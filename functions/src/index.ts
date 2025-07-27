import {initializeApp} from "firebase-admin/app";

import {getFirestore} from "firebase-admin/firestore";
import {logger, setGlobalOptions} from "firebase-functions";
import functions = require("firebase-functions/v1");
import {onCall} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {decrypt, encrypt} from "./crypto";


initializeApp();
setGlobalOptions({ region: "europe-west3" });
const db = getFirestore();

const aesKey = defineSecret("AES_KEY");

exports.setupUser = functions.region("europe-west3").auth.user().onCreate(async (user) => {
    await db.doc("/users/" + user.uid).create({
        member: null
    });
    logger.log("Created user doc with id", user.uid);
})

exports.deleteUser = functions.region("europe-west3").auth.user().onDelete(async (user) => {
    await db.doc("/users/" + user.uid).delete();
    logger.log("Deleted user doc with id ", user.uid);
})

exports.getEncryptedMemberId = onCall(async (request)=> {
    if (!request.auth || !request.data || !request.data["id"] || typeof request.data["id"] != "string") {
        return {error: true, reason: "No auth or request data"};
    }

    const memberId = request.data["id"];
    const invitingMemberId = (await db.doc(`/users/${request.auth.uid}`).get()).get("member");

    if(!invitingMemberId) {
        return {error: true, reason: "Inviting user has no member assigned"};
    }

    const [invitingMember, invitedMember] = await Promise.all([db.doc(`/members/${invitingMemberId}`).get(),
        db.doc(`/members/${memberId}`).get()]);
    const invitingRoles = invitingMember.data()?.roles ?? {};
    const invitedRoles = invitedMember.data()?.roles ?? {};

    let allowed = false;
    if(invitingRoles["admin"]) {
        allowed = true;
    } else if(invitingRoles["coach"] && invitedRoles["player"]) {
        // intersect coached teams and member's teams
        // if one is in both, the action is allowed

        // usually only 1 to 2 items per array; so a set is not necessary for performance
        const intersect: string[] = invitingRoles["coach"].filter((value: any) => invitedRoles["player"].includes(value));

        allowed = intersect.length > 0;
    }

    if (!allowed) {
        return {error: true, reason: "No permission"};
    }

    return {error: false, cipher: encrypt(memberId, aesKey.value())};
});

exports.assignUserToMember = onCall(async (request) => {
    if (!request.auth || !request.data || !request.data["cipher"] || typeof request.data["cipher"] != "string") {
        return {error: true, reason: "No auth or request data"};
    }
    const cipher = request.data["cipher"];

    let memberId;
    try {
        memberId = decrypt(cipher, aesKey.value())
    } catch (e) {
        logger.error(e);
        return {error: true, reason: "Decryption failed"};
    }

    const memberDoc = await db.doc(`/members/${memberId}`).get();
    if (memberDoc.data()?.user) {
        return {error: true, reason: "member already assigned"};
    }

    const batch = db.batch();
    batch.update(db.doc(`/users/${request.auth.uid}`), {
        member: memberId
    });
    batch.update(db.doc(`/members/${memberId}`), {
        user: request.auth.uid
    });
    await batch.commit();

    return {error: false};
});