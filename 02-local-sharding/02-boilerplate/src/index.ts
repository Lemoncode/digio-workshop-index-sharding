import './load-env.js';
import { MongoClient } from 'mongodb';
import { envConstants } from './env.constants.js';

const client = new MongoClient(envConstants.MONGODB_URI);

const db = client.db();

const count = await db.collection('clients').countDocuments();
console.log({ count });
