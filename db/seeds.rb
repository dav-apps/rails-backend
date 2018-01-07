# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
users = User.create([
   {email: "dav@dav-apps.tech", password: "davdavdav", username: "dav", confirmed: true},
   {email: "test@example.com", password: "password", username: "testuser", confirmed: true},
   {email: "nutzer@testemail.com", password: "blablablablabla", username: "nutzer", confirmed: false},
   {email: "normalo@helloworld.net", password: "schoeneheilewelt", username: "normalo", confirmed: true}
])

devs = Dev.create([
   {user: users.first, api_key: "eUzs3PQZYweXvumcWvagRHjdUroGe5Mo7kN1inHm", secret_key: "Stac8pRhqH0CSO5o9Rxqjhu7vyVp4PINEMJumqlpvRQai4hScADamQ", uuid: "d133e303-9dbb-47db-9531-008b20e5aae8"},
   {user: users.second, api_key: "MhKSDyedSw8WXfLk2hkXzmElsiVStD7C8JU3KNGp", secret_key: "5nyf0tRr0GNmP3eB83pobm8hifALZsUq3NpW5En9nFRpssXxlZv-JA", uuid: "71a5d4f8-083e-413e-a8ff-66847a5f3a97"}
])

apps = App.create([
   {dev: devs.first, name: "Cards", description: "This is a vocabulary app!", published: true},
   {dev: devs.second, name: "TestApp", description: "This is a test app.", published: false}
])

tables = Table.create([
   {name: "Card", app: apps.first},
   {name: "TestTable", app: apps.second}
])