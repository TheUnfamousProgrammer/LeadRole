import * as jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) throw new Error("missing_JWT_SECRET");

export function signToken(payload: object, expiresIn: jwt.SignOptions['expiresIn'] = "7d") {
    return jwt.sign(payload, JWT_SECRET as jwt.Secret, { expiresIn });
}

export function verifyToken<T = any>(token: string): T {
    return jwt.verify(token, JWT_SECRET as jwt.Secret) as T;
}