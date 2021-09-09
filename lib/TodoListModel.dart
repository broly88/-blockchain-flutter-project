import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class TodoListModel extends ChangeNotifier{
  List<Task> todos = [];
  bool isLoading = true;
  final String _rpcUrl = "http://146.141.152.68:7545";
  final String _wsUrl = "ws://146.141.152.68:7545/";

  final String _privateKey = "eb9b98d489a016cdeb339412029e9c0d49e267fd2bf3c17d57cf7ff55fa4d16e";

  int taskCount = 0;
  late Web3Client _client;
  late String _abiCode;
  late Credentials _credentials;
  late EthereumAddress _contractAddress;
  late EthereumAddress _ownAddress;
  late DeployedContract _contract;
  late ContractFunction _taskCount;
  late ContractFunction _todos;
  late ContractFunction _createTask;
  late ContractEvent _taskCreatedEvent;

  TodoListModel() {
    initiateSetup();
  }

  Future<void> initiateSetup() async {
    _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });

    await getAbi();
    await getCredentials();
    await getDeployedContract();
  }

  Future<void> getAbi() async {
    String abiStringFile =
        await rootBundle.loadString("src/abis/TodoList.json");
    var jsonAbi = jsonDecode(abiStringFile);

    //this saves the abi code
    _abiCode = jsonEncode(jsonAbi["abi"]);

    //finding the contract address
    _contractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
    print(_contractAddress);
  }

  Future<void> getCredentials() async {
    _credentials = await _client.credentialsFromPrivateKey(_privateKey);
    _ownAddress = await _credentials.extractAddress();
  }

  //this function will give us a copy of the deployed contract
  Future<void> getDeployedContract() async {
    _contract = DeployedContract(
        ContractAbi.fromJson(_abiCode, "TodoList"), _contractAddress);

    _taskCount = _contract.function("taskCount");
    _createTask = _contract.function("createTask");
    _todos = _contract.function("todos");
    _taskCreatedEvent = _contract.event("TaskCreated");
    getTodos();
    // print("");
  }

    getTodos() async {
    List totalTasksList = await _client
        .call(contract: _contract, function: _taskCount, params: []);

    BigInt totalTasks = totalTasksList[0];
    taskCount = totalTasks.toInt();
    print(totalTasks);
    todos.clear();
    for (var i = 0; i < totalTasks.toInt(); i++) {
      var temp = await _client.call(
          contract: _contract, function: _todos, params: [BigInt.from(i)]);
      todos.add(Task(taskName: temp[0], isCompleted: temp[1]));
    }

    isLoading = false;
    notifyListeners();
  }

  addTask(String taskNameData) async {
    isLoading = true;
    notifyListeners();
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _createTask,
            parameters: [taskNameData]));

    getTodos();
  }

}

class Task {
  String taskName;
  bool isCompleted;
  Task({required this.taskName, required this.isCompleted});
}