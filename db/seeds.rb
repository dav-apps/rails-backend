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
   {email: "normalo@helloworld.net", password: "schoeneheilewelt", username: "normalo", confirmed: true},
   {email: "davClassLibraryTest@dav-apps.tech", password: "davClassLibrary", username: "davClassLibraryTestUser", confirmed: true}
])

devs = Dev.create([
   {user: users.first, api_key: "eUzs3PQZYweXvumcWvagRHjdUroGe5Mo7kN1inHm", secret_key: "Stac8pRhqH0CSO5o9Rxqjhu7vyVp4PINEMJumqlpvRQai4hScADamQ", uuid: "d133e303-9dbb-47db-9531-008b20e5aae8"},
   {user: users.second, api_key: "MhKSDyedSw8WXfLk2hkXzmElsiVStD7C8JU3KNGp", secret_key: "5nyf0tRr0GNmP3eB83pobm8hifALZsUq3NpW5En9nFRpssXxlZv-JA", uuid: "71a5d4f8-083e-413e-a8ff-66847a5f3a97"}
])

apps = App.create([
   {dev: devs.first, name: "Cards", description: "This is a vocabulary app!", published: true, link_web: "http://cards.dav-apps.tech"},
   {dev: devs.second, name: "TestApp", description: "This is a test app.", published: false, link_play: "https://play.google.com"},
   {dev: devs.second, name: "davClassLibraryTestApp", description: "This is the test app for davClassLibrary", published: false}
])

tables = Table.create([
   {name: "Card", app: apps.first},
   {name: "TestTable", app: apps.second},
   {name: "TestData", app: apps.third},
   {name: "TestFile", app: apps.third}
])

table_objects = TableObject.create([
	{table: tables[2], user: users[4], uuid: "642e6407-f357-4e03-b9c2-82f754931161", file: false},
   {table: tables[2], user: users[4], uuid: "8d29f002-9511-407b-8289-5ebdcb5a5559", file: false},
   {table: tables[3], user: users[4], uuid: "4c8513e8-67c3-4067-8d80-bc2ed0459918", file: false}
])

properties = Property.create([
	{table_object: table_objects.first, name: "page1", value: "Hello World"},
	{table_object: table_objects.first, name: "page2", value: "Hallo Welt"},
	{table_object: table_objects.second, name: "page1", value: "Table"},
	{table_object: table_objects.second, name: "page2", value: "Tabelle"}
])