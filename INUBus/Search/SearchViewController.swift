//
//  SearchViewController.swift
//  INUBus
//
//  Created by 임현규 on 12/08/2019.
//  Copyright © 2019 zun. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
  
  let cellIndentifier = "SearchTableViewCell"
  
  let url = Server.address.rawValue + StringConstants.nodeData.rawValue
  
  let dateFormatter: DateFormatter = {
    let formatter: DateFormatter = DateFormatter()
    formatter.dateFormat = "yyyy.MM.dd"
    return formatter
  }()
  
  let date: Date = Date()
  var searchList = [String]()
  var searchHistory = [String]()
  var saveNextStops = [String]()
  var busInfo = [String]()
  var word: String = ""
  var save = [String]()
  var busNode = [String: String]()
  var busNodeArr = [String]()
  var busNodeNumArr = [String]()
  var busNodeNumber = [String]()
  
  @IBOutlet weak var searchTableView: UITableView!
  @IBOutlet weak var searchTextField: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setUp()
    request()
    loadHistory()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  @IBAction func backButtonDidTap(_ sender: Any) {
    self.navigationController?
      .popViewController(animated: true)
  }
  
  //검색값이 바뀔때마다 실행
  @IBAction func editingChanged(_ sender: Any) {
    
    word = searchTextField.text!
    
    searchList = []
    saveNextStops = []
    
    var temp = 0
    var tempArr = [String]()
    
    //사용자가 검색한 값이 서버로 받아온 버스번호에 포함되면 표시
    for busNumber in busInfo {
      if busNumber.contains(word) {
        searchList.insert(busNumber, at: 0)
        //값을 비교하는 과정에서 다른 값을 줘서 버스 번호
        saveNextStops.insert("\(busNumber)@", at: 0)
      }
    }
    
    //사용자가 검색한 값이 서버로 받아온 버스정거장에 포함되면 표시
    for busStops in busNodeArr {
      if busStops.contains(word) {
        for(key, value) in busNode {
          //value(정거장)값과 사용자가 검색한 값이 같으면
          if value == busStops {
            //해당 value의 key(정거장번호)와 value를 저장
            //각각 다른 배열이지만 정거장과 번호가 배열 순서가 같게 됨
            saveNextStops.append(key)
            searchList.append(value)
          }
        }
      }
    }

    //검색 결과에 정거장 번호가 겹치는 정거장들을 제거하는 위함
    for checkStops in saveNextStops {
      temp += 1
      for num in temp..<(saveNextStops.count) {
        if checkStops == saveNextStops[num] {
          saveNextStops.remove(at: num)
          //임의의 값을 저장함(이후에 "!"를 이용해 겹치는 값들 삭제)
          //그냥 saveNextStops.remove만해버리면 배열의 index가 꼬임
          saveNextStops.insert("\(temp)!", at: num)
          searchList.remove(at: num)
          searchList.insert("\(temp)!", at: num)
        }
    }
  }
    
    //"!"를 이용해 정거장 번호가 겹치는 정거장 제거
    for num in 0..<(saveNextStops.count) {
      if saveNextStops[num].contains("!") {
        //"!"가 있는 원소들만 추춣하여 배열의 맨앞으로 보냄
        saveNextStops.insert(saveNextStops[num], at: 0)
        //tempArr를 만들어 "!"원소들을 저장
        tempArr.insert(saveNextStops[num+1], at: 0)
        //맨앞으로 보내진 원소들은 제거
        saveNextStops.remove(at: num+1)
      }
    }
    
    for num in 0..<(searchList.count) {
      if searchList[num].contains("!") {
        searchList.insert(searchList[num], at: 0)
        searchList.remove(at: num+1)
      }
    }
    
    //tempArr의 개수 만큼 "!"원소들 제거
    for num in 0..<(tempArr.count) {
      saveNextStops.remove(at: 0)
      searchList.remove(at: 0)
    }
    
    self.searchTableView.reloadData()
  }
  
  //저장된 검색기록을 가져오는 함수
  func loadHistory() {
    
    guard let saveText =
      UserDefaults.standard.object(forKey: "saveText") as?
        [String] else { return }
    
    searchHistory = saveText
  }
}

extension SearchViewController {
  
  func setUp() {
    searchTableView.delegate = self
    searchTableView.dataSource = self
    //searchTabelView가 cellIndentifier라는 custom cell을 렌더링하게 설정
    searchTableView.register(UINib(nibName: cellIndentifier, bundle: nil),
                             forCellReuseIdentifier: cellIndentifier)
    searchTableView.tableFooterView = UIView()
    searchTextField.delegate = self

  }
  
  //서버로부터 버스 번호, 노선을 받아오는 함수
  func request() {
    guard let url = URL(string: url) else { return }
    
    NetworkManager.shared.request(url: url, method: .get) { (data, error) in
      if let error = error {
        print(error.localizedDescription)
      }
      
      if let data = data {
        do {
          let busNumbers = try JSONDecoder().decode([Route].self, from: data)
          
          for busNumber in busNumbers {
            
            self.busInfo.append(busNumber.no)
            
            for busNode in busNumber.nodeList {
              
              self.busNode.updateValue(busNode.nodeName, forKey: "\(busNode.nodeNo)")
            }
          }
          for busNodes in self.busNode.values {
            self.busNodeArr.append(busNodes)
          }
        } catch {
          print(error.localizedDescription)
        }
      }
      ProgressIndicator.shared.hide()
    }
  }
  
  //검색 결과에서 버스정거장을 클릭했을때 알림
  func sorryAlert() {
    
    let alert =
      UIAlertController(title: "알림",
      message: "\n버스 정거장 검색은 현재 지원하지 않습니다.\n 버스 번호 검색을 이용해 주시기 바랍니다.",
      preferredStyle: .alert)
    let action = UIAlertAction(title: "확인", style: .default, handler: nil)
    
    alert.addAction(action)
    
    present(alert, animated: true, completion: nil)
  }
}

extension SearchViewController: UITableViewDelegate {
  
  //cell의 높이
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 77
  }
  
  //cell이 선택되면 RouteViewController로 이동
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if searchTextField.isEditing {
      
      //cell이 선택되면 해당 row의 값이 검색기록으로 들어감
      save = searchHistory
      save.insert(searchList[indexPath.row], at: 0)
      UserDefaults.standard.set(save, forKey: "saveText")
      
      switch searchList[indexPath.row] {
      //검색목록의 해당 row의 버스정보가 버스 번호일때
      case "81", "82", "16", "1301", "6", "6-1",
           "6-2", "780", "780-1", "780-2", "92", "3002", "6405", "908", "909":
        
        let viewController = UIStoryboard(name: "Route", bundle: nil)
          .instantiateViewController(withIdentifier: "RouteViewController")
        
        //RouteViewController에 busNo을 주기 위함
        if let routeViewController = viewController as? RouteViewController {
          routeViewController.busNo = searchList[indexPath.row]
        }
        self.navigationController?.pushViewController(viewController, animated: true)
        
      //정류장일떄
      default:
        sorryAlert()
      }
      
      //검색기록이 보여지고 있는 상태일때
    } else {
      
      switch searchHistory[indexPath.row] {
      //검색기록의 해당 row의 버스정보가 버스 번호일때
      case "81", "82", "16", "1301", "6", "6-1",
           "6-2", "780", "780-1", "780-2", "92", "3002", "6405", "908", "909":
        
        let viewController = UIStoryboard(name: "Route", bundle: nil)
          .instantiateViewController(withIdentifier: "RouteViewController")
        if let routeViewController = viewController as? RouteViewController {
          routeViewController.busNo = searchHistory[indexPath.row]
        }
        self.navigationController?.pushViewController(viewController, animated: true)
        
      //정류장일때
      default:
        sorryAlert()
      }
    }
  }
}

extension SearchViewController: UITableViewDataSource {
  //section마다의 cell개수
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if searchTextField.isEditing {
      return searchList.count
    } else {
      return searchHistory.count
    }
  }
  
  //section의 개수
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  //cell에 대한 정보
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let cell = searchTableView.dequeueReusableCell(withIdentifier:
      cellIndentifier, for: indexPath) as?
      SearchTableViewCell else { return UITableViewCell() }
    
    if searchTextField.isEditing {
      cell.searchLabel.text = searchList[indexPath.row]
      cell.moreInfo.text = "정류장 번호: " + saveNextStops[indexPath.row]
      cell.dayLabel.text = self.dateFormatter.string(from: date)
      cell.deleteButton.isHidden = true
    } else {
      cell.searchLabel.text = searchHistory[indexPath.row]
      cell.moreInfo.text = ""
      cell.dayLabel.text = self.dateFormatter.string(from: date)
      cell.deleteButton.isHidden = false
    }

    //cell의 deletieButton이 누르면 did함수 실행
    cell.deleteButton.addTarget(self, action: #selector(reload), for: .touchUpInside)
    
    switch cell.searchLabel.text {
    case "3002", "1301", "6405":
      cell.searchLabel.textColor = UIColor(red: 255/255, green: 97/255, blue: 7/255, alpha: 1)
      cell.moreInfo.text = "직행버스"
    case "780", "780-1", "780-2", "81", "82", "16", "6", "6-1", "6-2":
      cell.searchLabel.textColor = UIColor(red: 0/255, green: 111/255, blue: 255/255, alpha: 1)
      cell.moreInfo.text = "간선버스"
    case "92":
      cell.searchLabel.textColor = UIColor(red: 36/255, green: 195/255, blue: 48/255, alpha: 1)
      cell.moreInfo.text = "지선버스"
    case "908", "909":
      cell.searchLabel.textColor = UIColor(red: 105/255, green: 0/255, blue: 181/255, alpha: 1)
      cell.moreInfo.text = "간선급행버스"
    default:
      cell.searchLabel.textColor = UIColor(red: 0/255, green: 97/255, blue: 244/255, alpha: 1)
    }
    return cell
  }
  
  //delete button을 눌렀을 때 변경된 값을 받아와 테이블뷰를 reload하는 함수
  @objc func reload() {
    guard let text = UserDefaults.standard.object(forKey: "saveText") as? [String] else { return }
    
    searchHistory = text
    
    searchTableView.reloadData()
    }
  }

extension SearchViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    //return이 입력되면 키보드를 내려줌
    searchTextField.resignFirstResponder()
    
    return true
  }
}
