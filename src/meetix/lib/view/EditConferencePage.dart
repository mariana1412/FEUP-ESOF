import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:meetix/controller/AuthController.dart';
import 'package:flutter/material.dart';
import 'package:meetix/controller/FunctionsController.dart';
import 'package:meetix/controller/StorageController.dart';
import 'package:meetix/view/ConferenceListPage.dart';
import 'package:meetix/view/ConferencePage.dart';
import 'package:meetix/view/MyWidgets.dart';
import 'package:provider/provider.dart';

import '../model/Conference.dart';
import '../controller/FirestoreController.dart';

class EditConferencePage extends StatefulWidget {
  final FirestoreController _firestore;
  final StorageController _storage;
  final FunctionsController _functions;
  final Conference _conference;

  EditConferencePage(this._firestore, this._storage,  this._functions, this._conference);

  @override
  _EditConferencePageState createState() => _EditConferencePageState(_conference);
}

class _EditConferencePageState extends State<EditConferencePage> {
  Conference _conference;

  _EditConferencePageState(this._conference);

  TextEditingController _nameController = TextEditingController();
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();
  TextEditingController _interestsController = TextEditingController();


  bool _nameValid = true;
  bool _startDateValid = true;
  bool _endDateValid = true;
  bool _interestsValid = true;
  String profileImgUrl = 'default-conference.png';
  File profileImg;

  Map updates = Map<String,dynamic>();

  @override
  initState(){
    super.initState();

    profileImgUrl = _conference.img;
  }

  String _readableDate(DateTime date) {
    return "${date.toLocal().day}/${date.toLocal().month}/${date.toLocal().year}";
  }

  submitForm() {
    setState(() {
      (_nameController.text.isEmpty || _nameController.text.length >= 3)? _nameValid = true : _nameValid = false;
      // (_interestsController.text.isEmpty)? _interestsValid = true : _interestsValid = false;
    });

    if (_nameValid && _startDateValid && _endDateValid && _interestsValid) {
      if(profileImg != null){
        profileImgUrl = 'conferences/' + _conference.reference.id + '/conference_img';
      }

      if(_nameController.text.isNotEmpty && _nameController.text != _conference.name)
        updates['name'] = _nameController.text;
      if(_startDateController.text.isNotEmpty && _startDateController.text.isNotEmpty)
        updates['start_date'] = Timestamp.fromDate(_conference.start_date);
      if(_endDateController.text.isNotEmpty && _endDateController.text.isNotEmpty)
        updates['end_date'] = Timestamp.fromDate(_conference.end_date);
      if(_interestsController.text.isNotEmpty && _interestsController.text != _conference.interests.join(", "))
        updates['interests'] = _interestsController.text.split(",").map((e) => e.trim()).toSet().where((e) => e.isNotEmpty).toList();

      _conference.reference.update(updates).then((value) async {
        if(profileImg != null) await widget._storage.uploadFile(profileImgUrl, profileImg);
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Conference")),
      body: _buildBody(context),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Text("Cancel", style: TextStyle(color: Colors.grey),)
              ),
              SizedBox(width: 20,),
              RaisedButton(
                onPressed: (){submitForm();},
                child: Text("Save changes", style: TextStyle(color: Colors.white),), color: Theme.of(context).accentColor,
              ),
            ],
          ),
        ),
        ),
      );
    }

  Widget _buildBody(BuildContext context) {
    return Container(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ListView(
          children: [
            SizedBox(height: 15),
            ShowAvatarEdit(
              storage: widget._storage,
              profileImgUrl: profileImgUrl,
              onFileChosen: (file) {profileImg = file;},
            ),
            SizedBox(height: 35),
            TextFieldWidget(
              labelText: "Name",
              hintText: _conference.name,
              controller: _nameController,
              isValid: _nameValid,
              defaultValue: _conference.name,
            ),
            SizedBox(height: 10),
            _dateSelector(context, true),
            SizedBox(height: 10),
            _dateSelector(context, false),
            SizedBox(height: 10),
            TextFieldWidget(
              labelText: "Interests",
              hintText: "Interests",
              controller: _interestsController,
              isValid: _interestsValid,
              defaultValue: _conference.interests.join(", "),
            ),
          ],
        ),
      ),
    );
  }

  _selectDate(BuildContext context, TextEditingController destination, bool start) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: (start || _conference.end_date == null)? _conference.start_date : _conference.end_date,
        firstDate: (start)? DateTime.now() : _conference.end_date,
        lastDate: (start && _conference.end_date != null)? _conference.end_date : DateTime(2100),
        helpText: (start)? "Select start date" : "Select end date"
    );
    if (picked != null)
      setState(() {
        var date = _readableDate(picked);
        if (start) {
          _conference.start_date = picked;
          _startDateController.text = date;
        }
        else {
          _conference.end_date = picked;
          _endDateController.text = date;
        }
      });
  }

  Widget _dateSelector(BuildContext context, bool start) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _selectDate(context, _startDateController, start);
      },
      child: Container(
        color: Colors.transparent,
        child: IgnorePointer(
          child: TextFieldWidget(
            labelText: (start)? "Start Date" : "End Date",
            hintText: (start)? _readableDate(_conference.start_date) : _readableDate(_conference.end_date),
            hintWeight: FontWeight.w400,
            controller: (start)? _startDateController : _endDateController,
            isValid: (start)? _startDateValid : _endDateValid,
          ),
        ),
      ),
    );
  }
}

