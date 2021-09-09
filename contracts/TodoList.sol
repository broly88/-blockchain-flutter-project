pragma solidity ^0.5.1;

contract TodoList{
    uint public taskCount;
    
    constructor() public{
        todos[0] = Task('test',true);
        taskCount = 1;
    }
    
    struct Task{
        string taskName;
        bool isComplete;
    }
    
    mapping(uint => Task) public todos;
    
    event TaskCreated(string task, uint taskNumber);
    

    
    function createTask(string memory _taskName) public{
        //add task to mapping
        //increment task taskCount
        //emit event
        
        todos[taskCount++] = Task(_taskName, false);
        emit TaskCreated(_taskName, taskCount - 1);
    }
}