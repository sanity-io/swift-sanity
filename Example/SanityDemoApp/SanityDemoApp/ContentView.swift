// MIT License
//
// Copyright (c) 2021 Sanity.io

import Combine
import Sanity
import SDWebImageSwiftUI
import SwiftUI

let kQuery = """
*[_type == "movie"] {
    _id,
    releaseDate,
    slug,
    overview,
    title,
    popularity,
    poster,
    "screenings": *[_type == "screening" && references(^._id)] {
        _id,
        title,
        beginAt,
        endAt,
        ticket
    },
    "counter": coalesce(counter, 0)
}
"""

struct Movie: Decodable {
    static let queryAll = SanityDemoApp.sanityClient.query([Movie].self, query: kQuery)
    static let queryListen = SanityDemoApp.sanityClient.query(Movie.self, query: kQuery)

    struct Screening: Decodable {
        let _id: String
        let title: String
        let beginAt: String
        let endAt: String
        let ticket: SanityType.File?
    }

    let _id: String
    let releaseDate: String
    let slug: SanityType.Slug
    let overview: [SanityType.Block]
    let title: String
    let poster: SanityType.Image
    let popularity: Double
    let screenings: [Screening]? // This is optional since subqueries aren't supported in listeners
    let counter: Int

    func merge(with: Self) -> Movie {
        Movie(
            _id: with._id,
            releaseDate: with.releaseDate,
            slug: with.slug,
            overview: with.overview,
            title: with.title,
            poster: with.poster,
            popularity: with.popularity,
            screenings: with.screenings ?? self.screenings,
            counter: with.counter
        )
    }
}

class MoviesFetcher: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var error: Error? = nil
    @Published var ms: Int = 0
    @Published var queryString: String = ""

    private var fetchMoviesCancellable: AnyCancellable?
    private var listenMoviesCancellable: AnyCancellable?

    func fetchMovies() {
        fetchMoviesCancellable?.cancel()
        fetchMoviesCancellable = Movie.queryAll.fetch()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case let .failure(error):
                    self.error = error
                }
            }, receiveValue: { response in
                self.movies = response.result
                self.ms = response.ms
                self.queryString = response.query
            })
    }

    func listenMovies() {
        listenMoviesCancellable?.cancel()
        listenMoviesCancellable = Movie.queryListen.listen()
            .receive(on: DispatchQueue.main)
            .sink { update in
                guard let movie = update.result else {
                    return
                }
                if let index = self.movies.firstIndex(where: { $0._id == movie._id }) {
                    self.movies[index] = self.movies[index].merge(with: movie)
                }
            }
    }

    func cancel() {
        fetchMoviesCancellable?.cancel()
        listenMoviesCancellable?.cancel()
    }
}

extension Text {
    func blockContentChild(_ child: SanityType.Block.Child, markDefs: [SanityType.Block.MarkDef]) -> some View {
        var view = self
        if child.marks.contains(.em) {
            view = view.italic()
        }
        if child.marks.contains(.strong) {
            view = view.bold()
        }
        markDefs.forEach { markDef in
            guard let _ = child.marks.first(where: { mark in
                mark == .markDef(markDef._key)
            }) else {
                return
            }

            if markDef._type == "link" {
                view = view.foregroundColor(.blue)
            }
        }
        return view
    }
}

extension View {
    func blockContentChild(_ child: SanityType.Block.Child, markDefs: [SanityType.Block.MarkDef]) -> some View {
        let view = self
        markDefs.forEach { markDef in
            guard let _ = child.marks.first(where: { mark in
                mark == .markDef(markDef._key)
            }) else {
                return
            }
        }

        return view
    }
}

struct ErrorView: View {
    let error: Error

    var body: some View {
        if let error = self.error as? SanityClient.Query<[Movie]>.ErrorResponse, let queryError = error.queryError {
            Text("query error: \(queryError.queryError)").foregroundColor(.red)

            HStack {
                Text("query: \(queryError.query)")
                Spacer()
            }
        } else if let errorResponse = self.error as? SanityClient.Transaction.ErrorResponse {
            Text("mutation error: \(errorResponse.localizedDescription)")
        } else {
            Text("error: \(error.localizedDescription)").foregroundColor(.red)
        }
    }
}

struct MovieView: View {
    let movie: Movie
    @State var error: Error? = nil
    var movieImageURL: SanityImageUrl {
        SanityDemoApp.sanityClient.imageURL(movie.poster)
    }

    var body: some View {
        VStack {
            ZStack {
                WebImage(url: movieImageURL
                    .width(400)
                    .height(700)
                    .URL())
                    .resizable()
                    .scaledToFit()
                VStack {
                    HStack {
                        Spacer()
                        VStack {
                            Text("\(movie.popularity)")
                        }
                        .background(Color.red)
                        .rotationEffect(.init(degrees: 45))
                        .frame(width: 80, height: 80)
                    }
                    Spacer()
                    HStack {
                        Text(movie.title)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.bottom)
                    .padding(.horizontal)
                    .background(Color.black.opacity(0.6))
                }
            }
            .cornerRadius(20)
            VStack(alignment: .leading) {
                ForEach(movie.overview) { block in
                    HStack {
                        ForEach(block.children) { child in
                            Text("\(child.text)")
                                .blockContentChild(child, markDefs: block.markDefs)
                        }
                    }
                }
            }
            if let screenings = movie.screenings, screenings.count > 0 {
                VStack {
                    Text("Screenings").fontWeight(.bold)
                    ForEach(screenings, id: \._id) { screening in
                        VStack(alignment: .leading) {
                            Text(screening.title)
                            HStack {
                                Text("Begins at: \(screening.beginAt)")
                                Spacer()
                                Text("Ends at: \(screening.endAt)")
                            }
                            if let ticket = screening.ticket, let url = SanityDemoApp.sanityClient.fileURL(ticket) {
                                HStack {
                                    Link("Download ticket", destination: url)
                                }
                            }
                        }
                    }
                }
            }
            HStack {
                Text("Counter: ")
                Spacer()
                Text("\(movie.counter)")
            }
            Button("Increment movie counter") {
                Task {
                    let result = await SanityDemoApp.sanityClient.mutate([
                        .patch(documentId: movie._id, patches: [
                            Patch("counter", operation: .setIfMissing(0)),
                            Patch("counter", operation: .inc(1)),
                        ]),
                    ])
                    switch result {
                    case let .failure(error):
                        self.error = error
                    case .success:
                        break
                    }
                }
            }
            if let error = self.error {
                ErrorView(error: error)
            }
        }
    }
}

struct MoviesListView: View {
    let movies: [Movie]

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Movies").font(.title2)
                Spacer()
            }
            ForEach(self.movies, id: \._id) { movie in
                MovieView(movie: movie)
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var moviesFetcher = MoviesFetcher()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Button(action: {
                        self.moviesFetcher.cancel()
                    }) {
                        Text("Cancel")
                    }

                    Spacer()

                    Button(action: {
                        self.moviesFetcher.cancel()
                        self.moviesFetcher.fetchMovies()
                        self.moviesFetcher.listenMovies()
                    }) {
                        Text("Refresh")
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)

                if let error = self.moviesFetcher.error {
                    ErrorView(error: error)
                } else {
                    HStack {
                        Text("query: \(self.moviesFetcher.queryString.trimmingCharacters(in: .whitespacesAndNewlines))")
                        Spacer()
                    }
                    HStack {
                        Text("ms: \(self.moviesFetcher.ms)")
                        Spacer()
                    }
                }
                MoviesListView(movies: self.moviesFetcher.movies)
                Spacer()
            }
            .padding()
        }
        .onAppear {
            self.moviesFetcher.fetchMovies()
            self.moviesFetcher.listenMovies()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
