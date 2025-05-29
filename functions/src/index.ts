import {initializeApp} from "firebase-admin/app";

import {getFirestore} from "firebase-admin/firestore";
import {logger, setGlobalOptions} from "firebase-functions";
import functions = require("firebase-functions/v1");


initializeApp();
setGlobalOptions({ region: "europe-west3" });
const db = getFirestore();

exports.setupUser = functions.region("europe-west3").auth.user().onCreate(async (user) => {
    await db.doc("/users/" + user.uid).create({
        roles: []
    });
    logger.log("Created user doc with id ", user.uid);
})

exports.deleteUser = functions.region("europe-west3").auth.user().onDelete(async (user) => {
    await db.doc("/users/" + user.uid).delete();
    logger.log("Deleted user doc with id ", user.uid);
})