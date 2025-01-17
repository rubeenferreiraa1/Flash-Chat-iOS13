import UIKit
import Firebase
import FirebaseAuth
import FirebaseCore

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = [
        Message(sender: "1@2.com", body: "hey"),
        Message(sender: "a@b.com", body: "Hello"),
        Message(sender: "1@2.com", body: "what's up?")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        title = "⚡️FlashChat"
        navigationItem.hidesBackButton = true
        tableView.register(UINib(nibName: K.cellIdentifier, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
        
    }
    
    func loadMessages(){
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)
            .addSnapshotListener
        { [self] (querySnapshot, error) in
            messages = []
            if let e =  error {
                print("There was an issue retrieving data from Firestore, \(e)")
            }else {
                if let snapshotDocuments =  querySnapshot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        if let sender = data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField] as? String {
                            let newMessage = Message(sender: sender, body: messageBody)
                            self.messages.append(newMessage)
                            
                            DispatchQueue.main.sync {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let messageBody = messageTextfield.text , let messageSender = Auth.auth().currentUser?.email {
            db .collection(K.FStore.collectionName).addDocument(data:
                [K.FStore.senderField: messageSender,
                K.FStore.bodyField: messageBody,
                 K.FStore.dateField: Date().timeIntervalSince1970
                ]) { (error) in
                if let e = error {
                    print("there was an issue saving data on firestore, \(e)")
                }else {
                    print("Sucessfully saved data.")
                }
            }
        }
    }
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
    do {
        try Auth.auth().signOut()
        navigationController?.popToRootViewController(animated: true)
    } catch let signOutError as NSError {
      print("Error signing out: %@", signOutError)
        }
    }
}
extension ChatViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCellTableViewCell
        cell.textLabel?.text = messages[indexPath.row].body
        return cell
    }
}
