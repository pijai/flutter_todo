import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_todo/model/todo.dart';
import 'package:flutter_todo/util/constants.dart';
import 'package:flutter_todo/util/todoProvider.dart';

class NewTodo extends StatefulWidget {
  static final String ROUTE_NAME = '/new';
  Todo todo;

  NewTodo({Key key, this.todo}) : super(key: key){
    if(this.todo==null)
      this.todo = new Todo();
  }

  @override
  NewTodoState createState() => new NewTodoState();
}

class NewTodoState extends State<NewTodo> {

  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  Widget _createAppBar() {
    return new AppBar(
      title: new Text(_getTitle()),
      actions: <Widget>[_createSaveUpdateAction()],
    );
  }

  Widget _createSaveUpdateAction(){
    return new IconButton(
      onPressed: (){_saveTodo();},
      icon: const Icon(Icons.save),
    );
  }

   _saveTodo() async {
    if(_formKey.currentState.validate()){
        _formKey.currentState.save();
        TodoProvider provider = new TodoProvider();
        if(!_isExistRecord()) {
          await provider.insert(widget.todo);
        }else{
          await provider.update(widget.todo);
        }
        Navigator.of(context).pop();

    }
  }

  bool _isExistRecord(){
    return widget.todo.id == null ? false : true;
  }

  @override
  void initState(){
    super.initState();
  }

  @override
  void dispose(){
    super.dispose();
  }

  String _getTitle() {
    return _isExistRecord() ? Constants.TITLE_EDIT : Constants.TITLE_NEW;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(appBar: _createAppBar(),
    body: new Padding(padding: new EdgeInsets.fromLTRB(12.0, 18.0, 12.0, 18.0),
    child: new Form(
      onWillPop: _warnUserWithoutSaving,
        key: _formKey,
        child: new Column(
          children: <Widget>[
            _createNote()
          ],
        ),)),);
  }

  Future<bool> _warnUserWithoutSaving() async {
    if(_isExistRecord()){
      return true;
    }else {
      return await showDialog<bool>(
        context: context,
        child: new AlertDialog(
          title: const Text('Discard To do'),
          content: const Text('Do you want close without saving to do note?'),
          actions: <Widget>[
            new FlatButton(
              child: const Text('YES'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            new FlatButton(
              child: const Text('NO'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        ),
      ) ?? false;
    }
  }

  Widget _createNote(){
    return new TextFormField(
      decoration: const InputDecoration(
        contentPadding: const EdgeInsets.all(4.0),
        icon: const Icon(Icons.note),
        hintText: 'Note',
        labelText: 'What would you like to do ?',
      ),
      initialValue: widget.todo.note!=null ? widget.todo.note :'',
      keyboardType: TextInputType.text,
      validator: _validateNote,
      onSaved: _noteOnSave,
    );
  }

  String _validateNote(String value){
    return value.isEmpty ? 'Note is required': null;
  }

  void _noteOnSave(String value){
    widget.todo.note = value;
    widget.todo.date = new DateTime.now().toIso8601String();
  }

}
