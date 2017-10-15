# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
users = User.create([{username: "sherlock", email: "sherlock@example.com", password: "sherlocked"}, 
                    {username: "matt", email: "matt@test.com", password: "schachmatt"},
                    {username: "testuser", email: "testuser@email.com", password: "testpassword"}])
devs = Dev.create([{user: users.first},  # Sherlock
                    {user: users.second}]) # Matt

apps = App.create([{name: "TestApp", description: "This is a test app.", dev: devs.second}, # Matt
                    {name: "Cards", description: "This is an app for learning vocabulary.", dev: devs.first}]) # Sherlock

tables = Table.create([{name: "Note", app: apps.first}, {name: "Card", app: apps.second}])

objects = TableObject.create([{table: tables.first, user: users[0]},
                            {table: tables.first, user: users[0]},
                            {table: tables.first, user: users[1]},
                            {table: tables.first, user: users[1]},
                            {table: tables.first, user: users[2]},
                            {table: tables.first, user: users[2]},
                            {table: tables.second, user: users[0]},
                            {table: tables.second, user: users[0]},
                            {table: tables.second, user: users[1]},
                            {table: tables.second, user: users[1]},
                            {table: tables.second, user: users[2]},
                            {table: tables.second, user: users[2]}])

properties = Property.create([{table_object: objects[0], name: "title", value: "Hello World"},
                            {table_object: objects[0], name: "content", value: "This is my first note. Hello World!"},
                            {table_object: objects[1], name: "title", value: "Welt retten"},
                            {table_object: objects[1], name: "content", value: "Samstag, 9:30 in Petropavlovsk-Kamshatsky"},
                            {table_object: objects[2], name: "title", value: "Todos"},
                            {table_object: objects[2], name: "content", value: "1. Welt retten, 2. Meerschweinchen retten, 3. Hackbrett üben"},
                            {table_object: objects[3], name: "title", value: "Weltherschaftsplan"},
                            {table_object: objects[3], name: "content", value: "Den richtigen Namen von L herausfinden und ihn ins Death Note schreiben"},
                            {table_object: objects[4], name: "title", value: "Echter Name von L"},
                            {table_object: objects[4], name: "content", value: "L Lawliet"},
                            {table_object: objects[5], name: "title", value: "ACHTUNG SPOILER!!1!"},
                            {table_object: objects[5], name: "content", value: "Tschubakka stirbt am Ende von Harry Potter"},
                            {table_object: objects[6], name: "page1", value: "Hello World"},
                            {table_object: objects[6], name: "page2", value: "Hallo Welt"},
                            {table_object: objects[7], name: "page1", value: "Ubiquity"},
                            {table_object: objects[7], name: "page2", value: "Allgegenwärtigkeit"},
                            {table_object: objects[8], name: "page1", value: "blitzkrieg"},
                            {table_object: objects[8], name: "page2", value: "Blitzkrieg"},
                            {table_object: objects[9], name: "page1", value: "entrails"},
                            {table_object: objects[9], name: "page2", value: "Eingeweide"},
                            {table_object: objects[10], name: "page1", value: "mischievously"},
                            {table_object: objects[10], name: "page2", value: "bösartig"},
                            {table_object: objects[11], name: "page1", value: "ferocity"},
                            {table_object: objects[11], name: "page2", value: "Bösartigkeit"}])