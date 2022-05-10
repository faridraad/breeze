// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './Breeze.sol';
import '../libraries/ArraysUtility.sol';

contract Projects is Breeze {

    using ArraysUtility for *;

    enum TaskStatus {
        TODO,
        DOING,
        REVIEW,
        DONE
    }
    uint  taskId;
    struct Task {
        string title;
        string description;
        uint createDate;
        uint updateDate;
        uint amount;
        address assignee;
        address assigner;
        TaskStatus status;
    }
    uint  projectId;
    uint[] projectIds;    
    struct Project{
        uint createDate;
        string title;
        mapping(uint => Task) tasks;
        mapping(uint => string) budgets;
    }
    mapping(uint => Project) projects;

	constructor() Breeze(msg.sender) {
	}

    function addNewProject(string memory _title) public ownerOnly{
        Project storage project = projects[++projectId];
        project.title = _title;
        project.createDate = block.timestamp;
        projectIds.push(projectId);
    }

    function increaseBudget(uint _projectId , string memory _description) public payable {
        projects[_projectId].budgets[msg.value] = _description;
    }

    function addNewTask(uint _projectId, string memory _title, string memory _description, uint _amount) public ownerOnly{
        Task storage task = projects[_projectId].tasks[++taskId];
        task.assigner = owner;
        task.title = _title;
        task.description = _description;
        task.amount = _amount;
        task.status = TaskStatus.DOING;
        task.createDate = block.timestamp;
    }

    function updateTask(uint _projectId, uint _taskId, string memory _title, string memory _description, uint _amount) public ownerOnly{
        projects[_projectId].tasks[_taskId].title = _title;
        projects[_projectId].tasks[_taskId].description = _description;
        projects[_projectId].tasks[_taskId].amount = _amount;
        projects[_projectId].tasks[_taskId].updateDate = block.timestamp;
    }

    function assignTask(uint _projectId, uint _taskId, address _assignee) public{
        projects[_projectId].tasks[_taskId].assignee = _assignee;
        projects[_projectId].tasks[_taskId].assigner = msg.sender;
        projects[_projectId].tasks[_taskId].updateDate = block.timestamp;
    }

    function changeTaskStatus(uint _projectId, uint _taskId, TaskStatus _status) public{
        if(_status != TaskStatus.DONE) 
            changeTaskStatusAction(_projectId,_taskId, _status);
        else 
            doneTaskStatus(_projectId, _taskId);
	}

    function changeTaskStatusAction(uint _projectId, uint _taskId, TaskStatus _status) internal {
        projects[_projectId].tasks[_taskId].status = _status;
    }

    function doneTaskStatus(uint _projectId, uint _taskId) internal ownerOnly{
        changeTaskStatusAction(_projectId,_taskId,TaskStatus.DONE);
        Task memory currentTask = getTaskById(_projectId, _taskId);
        (bool success, ) = currentTask.assignee.call{value: currentTask.amount}("");
        require(success, "Transfer failed!");
    }

    function deleteTaskById(uint _projectId, uint _taskId) public ownerOnly{
        delete projects[_projectId].tasks[_taskId];
    }

    function getProjectById(uint _projectId) public view returns(uint id, string memory title, uint createDate){
        return (_projectId, projects[_projectId].title , projects[_projectId].createDate);
    }

    function getTaskById(uint _projectId, uint _taskId) public view returns(Task memory task){
        return projects[_projectId].tasks[_taskId];
    }

    function getProjectsCount() public view returns(uint count){
        return projectIds.length;
    }

    function deleteProject(uint _projectId) public ownerOnly{
		delete projects[_projectId];
		deleteProjectIdByShifting(_projectId);
	}

    function getProjectIdByIndex(uint _index) public view returns(uint id){
        return projectIds.findValueByIndex(_index);
    }

	function deleteProjectIdByShifting(uint _projectId) internal ownerOnly{
		uint _index = projectIds.findIndexByValue(_projectId);
        projectIds.deleteItemByIndex(_index);
	}

}