import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_todo/model/header.dart';
import 'package:flutter_todo/model/todo.dart';
import 'package:flutter_todo/model/view_type.dart';
import 'package:flutter_todo/ui/new_todo.dart';
import 'package:flutter_todo/util/todo_provider.dart';
import 'package:intl/intl.dart';

class TodoList extends StatefulWidget {
  @override
  TodoListState createState() => new TodoListState();
}

class TodoListState extends State<TodoList> {
  final DateFormat formatter = new DateFormat.yMMMMd("en_US");
  List<dynamic> _todoList = [];
  TodoProvider _todoProvider;
  bool _isToClose = false;
  final GlobalKey<ScaffoldState> key = new GlobalKey<ScaffoldState>();
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _todoProvider = new TodoProvider();
    _getTodoList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _getTodoList() async {
    await _todoProvider.getAllTodo().then((todoList) {
      setState(() {
        if (todoList != null) this._todoList = _getSortedTodoList(todoList);
      });
    });
  }

  Widget _createAppBar() {
    return new AppBar(
      leading: const Icon(Icons.beenhere),
      title: const Text('To Do List'),
      actions: <Widget>[
        new IconButton(
            icon: new Icon(Icons.search),
            onPressed: () {
              setState(() => _isSearchOpen = true);
            })
      ],
    );
  }

  Widget _createListView() {
    return new Scrollbar(
      child: new ListView.builder(
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) {
          return _createItemByViewType(_todoList[index]);
        },
        itemCount: _todoList.length,
        padding: const EdgeInsets.only(bottom: 8.0),
      ),
    );
  }

  Widget _createItemByViewType(dynamic item) {
    switch (item.getViewType()) {
      case ViewType.HEADER:
        return new Container(
          padding: new EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 16.0),
          child: new Text(item.date),
        );
      case ViewType.TODO:
        return _createListItem(item);

      default:
        return null;
    }
  }

  Widget _createFloatingActionButton() {
    return new FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _openNewTodo();
        });
  }

  Future _openNewTodo() async {
    //await Navigator.of(context).pushNamed(NewTodo.ROUTE_NAME);
    Todo todo = new Todo();
    await Navigator
        .of(context)
        .push(new CupertinoPageRoute(builder: (buildContext) {
      return new NewTodo(todo: todo);
    }));
    _getTodoList();
  }

  Widget _createListItem(Todo todo) {
    return new Dismissible(
        direction: DismissDirection.endToStart,
        key: new Key(todo.id.toString()),
        onDismissed: (dismissDirection) {
          _dismissListItem(todo);
        },
        child: new Card(
          child: new InkWell(
            onTap: () {
              _openEditTodo(todo);
            },
            child: new Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 8.0, 14.0, 8.0),
                child: _createListItemContent(todo)),
          ),
        ));
  }

  _dismissListItem(Todo todo) async {
    await _todoProvider.delete(todo.id);
    _todoList.remove(todo);
    _showSnackbar(todo);
  }

  Widget _createListItemContent(Todo todo) {
    return new Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _createListItemLeftContent(todo),
        _createListItemRightContent(todo)
      ],
    );
  }

  Widget _createListItemLeftContent(Todo todo) {
    return new Checkbox(
      value: todo.done,
      onChanged: (change) {
        setState(() => todo.done = change);
        _todoProvider.update(todo);
      },
    );
  }

  Widget _createListItemRightContent(Todo todo) {
    return new Expanded(
        child: new Text(
      todo.note,
      style: new TextStyle(
          color: Colors.black,
          fontSize: 16.0,
          decoration:
              todo.done ? TextDecoration.lineThrough : TextDecoration.none),
    ));
  }

  _showSnackbar(Todo todo) {
    key.currentState.hideCurrentSnackBar();
    key.currentState.showSnackBar(
      new SnackBar(
        duration: new Duration(seconds: 20),
        content: new Text('${todo.note} is deleted'),
        action: new SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            _undoTodo(todo);
          },
        ),
      ),
    );
  }

  _openEditTodo(Todo todo) {
    Navigator.of(context).push(new CupertinoPageRoute(builder: (buildContext) {
      return new NewTodo(todo: todo);
    }));
  }

  _undoTodo(Todo todo) async {
    await _todoProvider.insert(todo);
    _getTodoList();
    key.currentState.hideCurrentSnackBar();
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        child: new Scaffold(
          key: key,
          //appBar: _createAppBar(),
          body: _createBody(),
          floatingActionButton: _createFloatingActionButton(),
        ),
        onWillPop: _showSnackbarOnClose);
  }

  Widget _createBody() {
    return new Column(
      children: <Widget>[
        _isSearchOpen ? _createStatusBar() : new Container(),
        _isSearchOpen ? _createSearchBar() : _createAppBar(),
        new Expanded(child: _createListView())
      ],
    );
  }

  Widget _createStatusBar() {
    return new Container(
        color: Theme.of(context).primaryColor,
        width: MediaQuery.of(context).size.width,
        height: 24.0);
  }

  Widget _createSearchBar() {
    return new Material(
      color: Theme.of(context).primaryColor,
      elevation: 20.0,
      shadowColor: Colors.grey.shade900,
      child: new Container(
          padding: new EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
          width: MediaQuery.of(context).size.width,
          height: 56.0,
          child: _createSearchView()),
    );
  }

  Widget _createSearchView() {
    return new Card(
      elevation: 3.0,
      child: new Row(
        children: <Widget>[
          new Expanded(
              flex: 9,
              child: new TextField(
                  maxLines: 1,
                  onChanged: (value) {
                    _searchTodo(value).then((todoList) {
                      setState(() => this._todoList = todoList);
                    });
                  },
                  decoration: const InputDecoration(
                    fillColor: Colors.transparent,
                    contentPadding:
                        const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0),
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search',
                  ))),
          new Expanded(
            flex: 1,
            child: new IconButton(
              icon: new Icon(
                Icons.close,
                color: Colors.grey.withOpacity(0.8),
              ),
              onPressed: () {
                setState(() {
                  _isSearchOpen = false;
                  _searchTodo('').then((todoList) {
                    setState(() => this._todoList = todoList);
                  });
                });
              },
              padding: new EdgeInsets.only(left: 4.0, right: 8.0),
            ),
          )
        ],
      ),
    );
  }

  Future<bool> _showSnackbarOnClose() async {
    key.currentState.hideCurrentSnackBar();
    if (_isToClose) {
      SystemNavigator.pop();
    }
    key.currentState.showSnackBar(
      new SnackBar(
        duration: new Duration(seconds: 2),
        content: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new Icon(Icons.exit_to_app),
            new Text('Press back again to exit')
          ],
        ),
      ),
    );
    new Future.delayed(new Duration(seconds: 2), () {
      _isToClose = false;
    });
    _isToClose = true;
    return false;
  }

  Future<List<dynamic>> _searchTodo(String value) async {
    List<Todo> allTodo = [];
    await _todoProvider.getAllTodo().then((todoList) {
      if (value.isNotEmpty) {
        allTodo = todoList
            .where(
                (todo) => todo.note.toLowerCase().contains(value.toLowerCase()))
            .toList();
      } else {
        allTodo = todoList;
      }
    });
    return _getSortedTodoList(allTodo);
  }

  List<String> _getDateList(List<Todo> todoList) {
    List<String> dates = todoList.map((todo) => todo.date).toSet().toList();
    dates.sort((date1, date2) {
      return formatter.parse(date1).isAfter(formatter.parse(date2)) ? 1 : 0;
    });
    return dates;
  }

  List<dynamic> _getSortedTodoList(List<Todo> todoList) {
    List<dynamic> items = [];
    _getDateList(todoList).forEach((date) {
      items.add(new Header(date: date));
      items.addAll(todoList.where((todo) => todo.date == date).toList());
    });
    return items;
  }
}
