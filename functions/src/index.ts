import {initializeApp} from "firebase-admin/app";

import {getFirestore} from "firebase-admin/firestore";
import {logger, setGlobalOptions} from "firebase-functions";
import functions = require("firebase-functions/v1");
import {onCall} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {encrypt} from "./crypto";

initializeApp();
setGlobalOptions({ region: "europe-west3" });
const db = getFirestore();

const aesKey = defineSecret("AES_KEY");

exports.setupUser = functions.region("europe-west3").auth.user().onCreate(async (user) => {
    await db.doc("/users/" + user.uid).create({
        member: null
    });
    logger.log("Created user doc with id ", user.uid);
})

exports.deleteUser = functions.region("europe-west3").auth.user().onDelete(async (user) => {
    await db.doc("/users/" + user.uid).delete();
    logger.log("Deleted user doc with id ", user.uid);
})

exports.getEncryptedMembmerId = onCall(async (request, response)=> {
    if (!request.auth || !request.data || !request.data["id"] || typeof request.data["id"] != "string") {
        return {error: true, reason: "No auth or request data"};
    }

    const memberId = request.data["id"];
    const invitingMemberId = request.auth.uid;

    const [invitingMember, invitedMember] = await Promise.all([db.doc(`/members/${invitingMemberId}`).get(),
        db.doc(`/members/${memberId}`).get()]);
    const invitingRoles = ((invitingMember.data()?.roles ?? {}) as Map<String, any>);
    const invitedRoles = ((invitingMember.data()?.roles ?? {}) as Map<String, any>);

    let allowed = false;

    if(invitingRoles.has("admin")) {
        allowed = true;
    } else if(invitingRoles.has("coach") && invitedRoles.has("player")) {
        // intersect coached teams and member's teams
        // if one is in both, the action is allowed

        // usually only 1 to 2 items per array; so a set is not necessary for performance
        const intersect: string[] = invitingRoles.get("coach").filter((value: any) => invitedRoles.get("player").includes(value));

        allowed = intersect.length > 0;
    }

    if (!allowed) {
        return {error: true, reason: "No permission"};
    }

    return {error: false, value: encrypt({id: memberId}, aesKey.value())};
});