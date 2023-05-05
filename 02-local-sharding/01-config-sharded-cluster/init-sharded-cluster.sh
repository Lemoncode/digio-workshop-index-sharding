#!/bin/bash

docker exec config-server-1 mongosh --eval "
rs.initiate(
  {
    _id: 'config-server',
    configsvr: true,
    members: [
      { _id: 0, host: 'config-server-1:27017' },
      { _id: 1, host: 'config-server-2:27017' },
      { _id: 2, host: 'config-server-3:27017' }
    ]
  }
)
"

docker exec shard1-server-1 mongosh --eval "
rs.initiate(
  {
    _id: 'shard1',
    members: [
      { _id: 0, host: 'shard1-server-1:27017' },
      { _id: 1, host: 'shard1-server-2:27017' },
      { _id: 2, host: 'shard1-server-3:27017' }
    ]
  }
)
"

docker exec shard2-server-1 mongosh --eval "
rs.initiate(
  {
    _id: 'shard2',
    members: [
      { _id: 0, host: 'shard2-server-1:27017' },
      { _id: 1, host: 'shard2-server-2:27017' },
      { _id: 2, host: 'shard2-server-3:27017' }
    ]
  }
)
"

docker exec mongos-router mongosh --eval "
sh.addShard( 'shard1/shard1-server-1:27017,shard1-server-2:27017,shard1-server-3:27017')
sh.addShard( 'shard2/shard2-server-1:27017,shard2-server-2:27017,shard2-server-3:27017')
"
