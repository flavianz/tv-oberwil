import crypto from "crypto";

export function encrypt(data: string, key: string) {
    const iv = crypto.randomBytes(12); // GCM IV = 12 bytes
    const cipher = crypto.createCipheriv('aes-256-gcm', Buffer.from(key, "base64"), iv);

    const encrypted = Buffer.concat([cipher.update(data, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();

    return Buffer.concat([iv, tag, encrypted]).toString('base64') // all together
}

export function decrypt(ciphertextBase64: string, key: string): any {
    const buf = Buffer.from(ciphertextBase64, 'base64');

    const iv = buf.subarray(0, 12);
    const tag = buf.subarray(12, 28);
    const encrypted = buf.subarray(28);

    const decipher = crypto.createDecipheriv('aes-256-gcm', Buffer.from(key, "base64"), iv);
    decipher.setAuthTag(tag);

    const decrypted = Buffer.concat([
        decipher.update(encrypted),
        decipher.final()
    ]);

    return decrypted.toString('utf8');
}