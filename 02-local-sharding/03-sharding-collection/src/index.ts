import './load-env.js';
import { MongoClient } from 'mongodb';
import { envConstants } from './env.constants.js';

const client = new MongoClient(envConstants.MONGODB_URI);

const db = client.db();

await db.collection('movies').insertMany([
  {
    title: 'The Godfather',
    genres: ['crime', 'drama'],
  },
  {
    title: 'The Godfather: Part II',
    genres: ['crime', 'drama'],
  },
  {
    title: 'The Dark Knight',
    genres: ['action', 'crime', 'drama'],
  },
  {
    title: 'Parasite',
    genres: ['drama', 'thriller'],
  },
]);

const count = await db.collection('movies').countDocuments();
console.log({ count });
