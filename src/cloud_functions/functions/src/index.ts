import * as functions from 'firebase-functions'
import * as admin from 'firebase-admin'
admin.initializeApp()

import { FieldPath } from '@google-cloud/firestore'

const tools = require('firebase-tools');


const db = admin.firestore()

// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript
//

exports.getTop20 = functions.https.onCall(async (data, context) => {
    const profilesRef = db.collection("conference").doc(data.conferenceID).collection("profiles")
    const userRef = profilesRef.doc(data.profileID)
    const userLikesRef = userRef.collection("likes")

    const matchesQuery = await userLikesRef.where("match", "==", true).get()
    let matches : Array<String> = [];
    matchesQuery.forEach(element => {
        matches.push(element.id)
    });
    
    const userInterestsQuery = await userRef.get()
    const userInterestsData = userInterestsQuery.data()
    let interests : Array<String> = [];
    interests = userInterestsData? userInterestsData["interests"] : [];
    
    let top : Array<Array<String>> = []
    if (interests && interests.length > 0) {
        const profilesQuery = await profilesRef.where(FieldPath.documentId(), "!=", data.profileID).where("interests", "array-contains-any", interests).get()
        profilesQuery.forEach(profile => {
            if (!matches.includes(profile.id)) {
                let profile_int = profile.data()["interests"]
                const common = profile_int.filter((interest : String) => interests.includes(interest))
                if (common.length > 0) {
                    top.push([profile.id, common.length])
                }
            }
        })
    }

    top.sort((a, b) => {return +b[1] - +a[1]})

    return top.slice(0, 5);
});

exports.deleteConference = functions.https.onCall(async (data, context) => {
    const conferencePath = "/conference/" + data.conferenceID
    const conferenceRef = db.doc(conferencePath)
    const conferenceData = (await conferenceRef.get()).data()
    const uid = conferenceData? conferenceData["uid"] : null
    if (!uid) {
        throw new functions.https.HttpsError(
            'internal',
            'Could not retrieve creator UID from conference. Possibly does not exist.'
        )
    }

    if (uid !== context.auth?.uid) {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Only conference creator can delete'
        )
    }

    await tools.firestore.delete(conferencePath, {
        project: process.env.GCLOUD_PROJECT,
        recursive: true,
        yes: true,
    })

    const bucket = admin.storage().bucket();

    bucket.deleteFiles({
        prefix: 'conferences/' + data.conferenceID,
    }, function(err) {
        if (err)
            console.log(err)
    },)

    return "Deleted documents and files for " + data.conferenceID
});