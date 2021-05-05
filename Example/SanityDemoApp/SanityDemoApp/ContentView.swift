//
// The MIT License (MIT)
// Copyright (C) 2021 - 2021.
//

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
    poster
}
"""

struct Movie: Decodable {
    static let queryAll = SanityDemoApp.sanityClient.query([Movie].self, query: kQuery)
    static let queryListen = SanityDemoApp.sanityClient.query(Movie.self, query: kQuery)

    let _id: String
    let releaseDate: String
    let slug: SanityType.Slug
    let overview: [SanityType.Block]
    let title: String
    let poster: SanityType.Image
    let popularity: Double

    func merge(with: Self) -> Movie {
        Movie(
            _id: with._id,
            releaseDate: with.releaseDate,
            slug: with.slug,
            overview: with.overview,
            title: with.title,
            poster: with.poster,
            popularity: with.popularity
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
                let movie = update.result
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
//        let markDefs = child.marks.compactMap { $0 == .markDef() }
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

//            if markDef._type == "link" {
//                view = Button(action: {
//                    guard let url = URL(string: markDef.link), UIApplication.shared.canOpenURL(url) else {
//                        return
//                    }
//                    UIApplication.shared.open(url, options: [])
//                }, label: view)
//            }
        }

        return view
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
//                if let error = self.moviesFetcher.error {
//                    if let error = self.moviesFetcher.error as? SanityClient.Query.ErrorResponse.Error {
//                        Text("query error: \(error.localizedDescription)").foregroundColor(.red)
//
//                        HStack {
//                            Text("query: \(error.queryErrorDescription)")
//                            Spacer()
//                        }
//                    } else {
//                        Text("error: \(error.localizedDescription)").foregroundColor(.red)
//                    }
//                }
//                else {
                HStack {
                    Text("query: \(self.moviesFetcher.queryString.trimmingCharacters(in: .whitespacesAndNewlines))")
                    Spacer()
                }
                HStack {
                    Text("ms: \(self.moviesFetcher.ms)")
                    Spacer()
                }
//                }
                ForEach(self.moviesFetcher.movies, id: \._id) { movie in
                    VStack {
                        ZStack {
                            WebImage(url: SanityDemoApp.sanityClient.imageURL(movie.poster, width: 400, height: 700))
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
                    }
                }
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
