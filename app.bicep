extension radius
extension radiusCompute
extension radiusSecurity
extension radiusData

param environment string
@secure()
param mysqlPassword string
param image string

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'radius-agent-demo'
  properties: {
    environment: environment
  }
}

resource dbSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'radius-agent-demo-dbsecret'
  properties: {
    application: app.id
    data: {
      password: mysqlPassword
    }
  }
}

resource database 'Radius.Data/mySqlDatabases@2025-08-01-preview' = {
  name: 'mysql'
  properties: {
    application: app.id
    environment: environment
    secretName: dbSecret.name
  }
}

resource containerImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'radius-agent-demo-image'
  properties: {
    application: app.id
    image: image
  }
}

resource frontend 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'radius-agent-demo-frontend'
  properties: {
    application: app.id
    environment: environment
    container: {
      image: containerImage.properties.image
      ports: {
        web: {
          containerPort: 3000
        }
      }
      env: {
        MYSQL_HOST: { value: database.properties.host }
        MYSQL_USER: { value: database.properties.username }
        MYSQL_PASSWORD: { valueFrom: { secretStoreRef: { name: dbSecret.name, key: 'password' } } }
        MYSQL_DB: { value: database.properties.database }
      }
    }
    connections: {
      containerImage: {
        source: containerImage.id
      }
      mysqldb: {
        source: database.id
      }
    }
  }
}

resource route 'Radius.Compute/routes@2025-08-01-preview' = {
  name: 'radius-agent-demo-route'
  properties: {
    application: app.id
    environment: environment
    port: 3000
  }
}
