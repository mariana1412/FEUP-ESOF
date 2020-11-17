import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../model/Conference.dart';

class FirestoreController {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getConferences() {
    return firestore.collection("conference").snapshots();
  }

  Stream<QuerySnapshot> getConferenceProfiles(Conference conference) {
    return conference.reference.collection("profiles").snapshots();
  }

  Stream<QuerySnapshot> getLikedYouProfiles(Conference conference, String profileID) {
    return conference.reference.collection("likes").where('liked', arrayContains: profileID).snapshots();
  }

  Stream<QuerySnapshot> getProfileById(Conference conference, String profileID) {
    return conference.reference.collection("profiles").where('uid', isEqualTo: profileID).snapshots();
  }

  Stream<DocumentSnapshot> getLikedProfiles(Conference conference, String profileID) {
    return conference.reference.collection("likes").doc(profileID).snapshots();
  }
  
  Stream<QuerySnapshot> getMatches(Conference conference, String profileID, List<dynamic> likedProfiles) {
    return conference.reference.collection("likes").where('liked', arrayContains: profileID)
         .where(FieldPath.documentId, whereIn: likedProfiles).snapshots();
  }

}