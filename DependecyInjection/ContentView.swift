//
//  ContentView.swift
//  DependecyInjection
//
//  Created by Andrea Monroy on 2/2/23.
//

import SwiftUI
import Combine //framework

struct PostsModel: Identifiable, Codable {
    let userId : Int
    let id : Int
    let title : String
    let body : String
}

protocol DataServiceProtocol {
    func getData()-> AnyPublisher<[PostsModel], Error>
}

//class that is in charge of fetching all the data
class ProductionDataService : DataServiceProtocol{
    
    //init a single instance of the class within the class and this is the only instance we use throughout the project
    //delete the singleton//static let instance = ProductionDataService()  //singleton
    
    
    
    //url string is optional by default so force unwrap it, however, DO NOT do this in a profuction app
    let url: URL
    
    init(url : URL ){
        self.url = url
    }
    
    func getData()-> AnyPublisher<[PostsModel], Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map({$0.data})
            .decode(type: [PostsModel].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        
    }
}

class MockDataService: DataServiceProtocol {
    
    let testData: [PostsModel]
    
    init(data: [PostsModel]?) {
        //?? otherwise
        self.testData = data ??  [
            PostsModel(userId: 1, id: 1, title: "one", body: "one"),
            PostsModel(userId: 2, id: 2, title: "two", body: "two")
            ]
    }
    
    func getData()-> AnyPublisher<[PostsModel], Error>{
        //A publisher that emits an output to each subscriber just once, and then finishes
        Just(testData)
            .tryMap({ $0 })
            .eraseToAnyPublisher() //gives an error becuase Just publisher can never fail, it will never actually throw an error so use .tryMap before so it's trying and it might fail or not
    }
}

//ViewModel
class DependencyInjectionViewModel: ObservableObject {

    
    
    @Published var dataArray: [PostsModel] = []
    var cancellables = Set<AnyCancellable>()
   
    //let datatService: ProductionDataService //reference to ProductionDataService
    //instead of passing a Production dataService pass protocol
    let dataService: DataServiceProtocol //passing anything that conforms to DataServiceProtocol
    
    //inject the protocol instead of the service
    init(dataService: DataServiceProtocol){
        self.dataService = dataService
        loadPosts()
    }
    
    private func loadPosts(){
        //instead of accessing the singleton
       // ProductionDataService.instance.getData()
        dataService.getData()
            .sink { _ in
              
            } receiveValue: { [weak self] returnedPosts in
                self?.dataArray = returnedPosts
            }
            .store(in: &cancellables)
    }
}


//View

struct ContentView: View {
    //not the = assign but the : because it's a type
    @StateObject private var vm: DependencyInjectionViewModel
    
    //the ViewModel is init here
    //injects the dataService in the ViewModel
    //inject protocol instead of service
    init(dataService: DataServiceProtocol){
        _vm = StateObject(wrappedValue: DependencyInjectionViewModel(dataService: dataService))
    }
    
    var body: some View {
        ScrollView{
            VStack{
                ForEach(vm.dataArray){ post in
                    Text(post.title)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {

    static let dataService = ProductionDataService(url: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
    
   /* static let dataService = MockDataService(data: [
    PostsModel(userId: 3, id: 3, title: "three", body: "three")
    ])*/
    
    static var previews: some View {
        ContentView(dataService: dataService)
    }
}
