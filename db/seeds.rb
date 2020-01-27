users = User.create([
   {email: "dav@dav-apps.tech", password: "davdavdav", username: "Dav", confirmed: true},
   {email: "test@example.com", password: "password", username: "testuser", confirmed: true},
   {email: "nutzer@testemail.com", password: "blablablablabla", username: "nutzer", confirmed: false},
   {email: "normalo@helloworld.net", password: "schoeneheilewelt", username: "normalo", confirmed: true},
	{email: "davClassLibraryTest@dav-apps.tech", password: "davClassLibrary", username: "davClassLibraryTestUser", confirmed: true},
	{email: "author@dav-apps.tech", password: "books", username: "PocketLib Author tester", confirmed: true}
])

devs = Dev.create([
   {user: users.first, api_key: "eUzs3PQZYweXvumcWvagRHjdUroGe5Mo7kN1inHm", secret_key: "Stac8pRhqH0CSO5o9Rxqjhu7vyVp4PINEMJumqlpvRQai4hScADamQ", uuid: "d133e303-9dbb-47db-9531-008b20e5aae8"},
   {user: users.second, api_key: "MhKSDyedSw8WXfLk2hkXzmElsiVStD7C8JU3KNGp", secret_key: "5nyf0tRr0GNmP3eB83pobm8hifALZsUq3NpW5En9nFRpssXxlZv-JA", uuid: "71a5d4f8-083e-413e-a8ff-66847a5f3a97"}
])

apps = App.create([
   {dev: devs.first, name: "Cards", description: "This is a vocabulary app!", published: true, link_web: "http://cards.dav-apps.tech"},
   {dev: devs.second, name: "TestApp", description: "This is a test app.", published: false, link_play: "https://play.google.com"},
   {dev: devs.second, name: "davClassLibraryTestApp", description: "This is the test app for davClassLibrary", published: false},
	{dev: devs.first, name: "UniversalSoundboard", description: "UniversalSoundboard is a customizable soundboard and music player", published: true},
   {dev: devs.first, name: "Calendo", description: "Manage your todos and appointments: Calendo is the best app to organize your life", published: true},
	{dev: devs.first, name: "PocketLib", description: "PocketLib is the library in your pocket", published: true},
	{dev: devs.first, name: "dav Website", description: "This is the app for the dav website", published: false}
])

tables = Table.create([
   {name: "Card", app: apps.first},
   {name: "TestTable", app: apps.second},
   {name: "TestData", app: apps.third},
	{name: "TestFile", app: apps.third},
	# UniversalSoundboard Tables
	{name: "Sound", app: apps[3]},
	{name: "SoundFile", app: apps[3]},
	{name: "ImageFile", app: apps[3]},
	{name: "Category", app: apps[3]},
	{name: "PlayingSound", app: apps[3]},
	{name: "Order", app: apps[3]},
   # Calendo Tables
   {name: "TodoList", app: apps[4]},
   {name: "Todo", app: apps[4]},
   {name: "Appointment", app: apps[4]},
   # PocketLib Tables
   {name: "Book", app: apps[5]},
   {name: "BookFile", app: apps[5]},
   {name: "App", app: apps[5]},
   {name: "EpubBookmark", app: apps[5]},
	{name: "Settings", app: apps[5]},
	{name: "Author", app: apps[5]},
	{name: "AuthorProfileImage", app: apps[5]},
	{name: "StoreBookCollection", app: apps[5]},
	{name: "StoreBookCollectionName", app: apps[5]},
	{name: "StoreBook", app: apps[5]},
	{name: "StoreBookCover", app: apps[5]},
	{name: "StoreBookFile", app: apps[5]}
])

table_objects = TableObject.create([
	{table: tables[2], user: users[4], uuid: "642e6407-f357-4e03-b9c2-82f754931161", file: false},
   {table: tables[2], user: users[4], uuid: "8d29f002-9511-407b-8289-5ebdcb5a5559", file: false},
	{table: tables[3], user: users[4], uuid: "4c8513e8-67c3-4067-8d80-bc2ed0459918", file: false},
	# Authors
	{table: tables[18], user: users[5], uuid: "099fbfa5-a6f1-41c1-99e9-0d02d8364f2d", file: false},
	{table: tables[18], user: users[0], uuid: "622ad623-b9a4-415d-92ee-a66f8a7f3c51", file: false},
	{table: tables[18], user: users[0], uuid: "1dd980fd-ae20-4566-b842-a25e241bfb46", file: false},
	# AuthorProfileImages
	{table: tables[19], user: users[5], uuid: "14e5ad81-3105-4cbc-85c8-4ffeec1c3812", file: true},
	{table: tables[19], user: users[0], uuid: "df45f27f-8ecb-41b0-864f-bb76669279f5", file: true},
	# StoreBookCollections
	{table: tables[20], user: users[5], uuid: "2cfe3d1a-2853-4e5c-9261-1942a9c5ddd9", file: false},
	{table: tables[20], user: users[5], uuid: "285a5fca-8db2-4f73-8b12-5d41cdac82ed", file: false},
	{table: tables[20], user: users[0], uuid: "921b2d9f-5565-442f-95c0-1658ee57146b", file: false},
	{table: tables[20], user: users[0], uuid: "21a9045f-4148-4e21-a701-8d19dd865d17", file: false},
	# StoreBookCollectionNames
		# First name of the first collection
	{table: tables[21], user: users[5], uuid: "5f0d68f0-fc99-457b-823a-b9994d17b6b1", file: false},
		# Second name of the first collection
	{table: tables[21], user: users[5], uuid: "f41d7646-b513-4af4-b93d-3813b1edfc3e", file: false},
		# First name of the second collection
	{table: tables[21], user: users[5], uuid: "9c2f12ad-0e94-4379-a0d6-7e087380bf5b", file: false},
		# Second name of the second collection
	{table: tables[21], user: users[5], uuid: "25060c42-e7bf-4187-9712-0a94c51d497c", file: false},
		# First name of the third collection
	{table: tables[21], user: users[0], uuid: "9ffb7b69-b9bc-45bc-ae94-34ec08c427c2", file: false},
		# First name of the fourth collection
	{table: tables[21], user: users[0], uuid: "5d8ebd0d-9e62-42bb-8565-963cbb6499d7", file: false},
	# StoreBooks
		# First book of the first collection
	{table: tables[22], user: users[5], uuid: "1cf6fc5f-8fa5-4972-895d-8b1d6552d41c", file: false},
		# Second book of the first collection
	{table: tables[22], user: users[5], uuid: "4df158a0-2157-4370-abac-dd3c25ca9ed3", file: false},
		# First book of the second collection
	{table: tables[22], user: users[5], uuid: "5242102c-b107-4e82-8eb8-bebe2a990436", file: false},
		# Second book of the second collection
	{table: tables[22], user: users[5], uuid: "617833c8-4d0a-4d78-acd0-306a90e346ba", file: false},
		# First book of the third collection
	{table: tables[22], user: users[0], uuid: "b0e4b01d-d53d-47b5-b5e4-48ea7bab6619", file: false},
		# Second book of the third collection
	{table: tables[22], user: users[0], uuid: "5aa1c310-cbc6-48b4-9000-63315e713d25", file: false},
		# First book of the fourth collection
	{table: tables[22], user: users[0], uuid: "13836f22-040f-4efd-9f30-9202184b23bf", file: false},
	# StoreBookCovers
	{table: tables[23], user: users[5], uuid: "bb63e1c9-866c-47b5-b852-e8473df404f3", file: true},
	# StoreBookFiles
	{table: tables[24], user: users[5], uuid: "b7cf0cee-fe8d-4f08-8b6e-d391065f1abb", file: true}
])

properties = Property.create([
	{table_object: table_objects[0], name: "page1", value: "Hello World"},
	{table_object: table_objects[0], name: "page2", value: "Hallo Welt"},
	{table_object: table_objects[1], name: "page1", value: "Table"},
	{table_object: table_objects[1], name: "page2", value: "Tabelle"},
	# Author properties
		# Properties for the first author
	{table_object: table_objects[3], name: "first_name", value: "Lemony"},
	{table_object: table_objects[3], name: "last_name", value: "Snicket"},
	{table_object: table_objects[3], name: "bio", value: "Dear reader, I'm sorry to tell you that I wrote some very unpleasant tales that you definitely should not read, if you want to further live a healthy life."},
	{table_object: table_objects[3], name: "profile_image", value: "14e5ad81-3105-4cbc-85c8-4ffeec1c3812"},
	{table_object: table_objects[3], name: "collections", value: "2cfe3d1a-2853-4e5c-9261-1942a9c5ddd9,285a5fca-8db2-4f73-8b12-5d41cdac82ed"},
		# Properties for the second author
	{table_object: table_objects[4], name: "first_name", value: "George"},
	{table_object: table_objects[4], name: "last_name", value: "Orwell"},
	{table_object: table_objects[4], name: "profile_image", value: "df45f27f-8ecb-41b0-864f-bb76669279f5"},
	{table_object: table_objects[4], name: "bio", value: "Eric Arthur Blair, better known by his pen name George Orwell, was an English novelist and essayist, journalist and critic. His work is characterised by lucid prose, awareness of social injustice, opposition to totalitarianism, and outspoken support of democratic socialism."},
		# Properties for the third author
	{table_object: table_objects[5], name: "first_name", value: "Aldous"},
	{table_object: table_objects[5], name: "last_name", value: "Huxley"},
	{table_object: table_objects[5], name: "bio", value: "Aldous Leonard Huxley was an English writer and philosopher. He wrote nearly fifty books — both novels and non-fiction works — as well as wide-ranging essays, narratives, and poems."},
	# StoreBookCollection properties
		# Properties for the first collection
	{table_object: table_objects[8], name: "author", value: "099fbfa5-a6f1-41c1-99e9-0d02d8364f2d"},
	{table_object: table_objects[8], name: "names", value: "5f0d68f0-fc99-457b-823a-b9994d17b6b1,f41d7646-b513-4af4-b93d-3813b1edfc3e"},
	{table_object: table_objects[8], name: "books", value: "1cf6fc5f-8fa5-4972-895d-8b1d6552d41c,4df158a0-2157-4370-abac-dd3c25ca9ed3"},
		# Properties for the second collection
	{table_object: table_objects[9], name: "author", value: "099fbfa5-a6f1-41c1-99e9-0d02d8364f2d"},
	{table_object: table_objects[9], name: "names", value: "9c2f12ad-0e94-4379-a0d6-7e087380bf5b"},
	{table_object: table_objects[9], name: "books", value: "5242102c-b107-4e82-8eb8-bebe2a990436"},
		# Properties for the third collection
	{table_object: table_objects[10], name: "author", value: "622ad623-b9a4-415d-92ee-a66f8a7f3c51"},
	{table_object: table_objects[10], name: "names", value: "9ffb7b69-b9bc-45bc-ae94-34ec08c427c2"},
		# Properties for the fourth collection
	{table_object: table_objects[11], name: "author", value: "622ad623-b9a4-415d-92ee-a66f8a7f3c51"},
	{table_object: table_objects[11], name: "names", value: "5d8ebd0d-9e62-42bb-8565-963cbb6499d7"},
	{table_object: table_objects[11], name: "books", value: "13836f22-040f-4efd-9f30-9202184b23bf"},
	# StoreBookCollectionName properties
		# Properties for the first collection name
	{table_object: table_objects[12], name: "name", value: "A Series of Unfortunate Events - Book the First"},
	{table_object: table_objects[12], name: "language", value: "en"},
		# Properties for the second collection name
	{table_object: table_objects[13], name: "name", value: "Eine Reihe betrüblicher Ereignisse - Der schreckliche Anfang"},
	{table_object: table_objects[13], name: "language", value: "de"},
		# Properties for the third collection name
	{table_object: table_objects[14], name: "name", value: "A Series of Unfortunate Events - Book the Second"},
	{table_object: table_objects[14], name: "language", value: "en"},
		# Properties for the fourth collection name
	{table_object: table_objects[15], name: "name", value: "Eine Reihe betrüblicher Ereignisse - Das Haus der Schlangen"},
	{table_object: table_objects[15], name: "language", value: "de"},
		# Properties for the fifth collection name
	{table_object: table_objects[16], name: "name", value: "1984"},
	{table_object: table_objects[16], name: "language", value: "en"},
		# Properties for the sixth collection name
	{table_object: table_objects[17], name: "name", value: "Animal Farm"},
	{table_object: table_objects[17], name: "language", value: "en"},
	# Store Book properties
		# Properties for the first store book
	{table_object: table_objects[18], name: "collection", value: "2cfe3d1a-2853-4e5c-9261-1942a9c5ddd9"},
	{table_object: table_objects[18], name: "title", value: "A Series of Unfortunate Events - Book the First"},
	{table_object: table_objects[18], name: "description", value: "Dear Reader, I'm sorry to say that the book you are holding in your hands is extremely unpleasant. It tells an unhappy tale about three very unlucky children."},
	{table_object: table_objects[18], name: "language", value: "en"},
	{table_object: table_objects[18], name: "status", value: "review"},
	{table_object: table_objects[18], name: "cover", value: "bb63e1c9-866c-47b5-b852-e8473df404f3"},
	{table_object: table_objects[18], name: "file", value: "b7cf0cee-fe8d-4f08-8b6e-d391065f1abb"},
		# Properties for the second store book
	{table_object: table_objects[19], name: "collection", value: "2cfe3d1a-2853-4e5c-9261-1942a9c5ddd9"},
	{table_object: table_objects[19], name: "title", value: "Eine Reihe betrüblicher Ereignisse - Der schreckliche Anfang"},
	{table_object: table_objects[19], name: "description", value: "Lieber Leser, es tut mir sehr Leid, aber das Buch, das du gerade in Händen hälst, ist außerordentlich unerfreulich. Es erzählt die traurige Geschichte von drei sehr bedauernswerten Kindern."},
	{table_object: table_objects[19], name: "language", value: "de"},
	{table_object: table_objects[19], name: "status", value: "review"},
		# Properties for the third store book
	{table_object: table_objects[20], name: "collection", value: "285a5fca-8db2-4f73-8b12-5d41cdac82ed"},
	{table_object: table_objects[20], name: "title", value: "A Series of Unfortunate Events - Book the Second"},
	{table_object: table_objects[20], name: "description", value: "Dear Reader, if you have picked up this book with the hope of finding a simple and cheery tale, I'm afraid you have picked up the wrong book altogether."},
	{table_object: table_objects[20], name: "language", value: "en"},
	{table_object: table_objects[20], name: "status", value: "unpublished"},
		# Properties for the fourth store book
	{table_object: table_objects[21], name: "collection", value: "285a5fca-8db2-4f73-8b12-5d41cdac82ed"},
	{table_object: table_objects[21], name: "title", value: "Eine Reihe betrüblicher Ereignisse - Das Haus der Schlangen"},
	{table_object: table_objects[21], name: "description", value: "Lieber Leser, wenn du dieses Buch zur Hand genommen hast in der Hoffnung, darin Zerstreuung und Vergnügen zu finden, dann liegst du leider völlig falsch."},
	{table_object: table_objects[21], name: "language", value: "de"},
	{table_object: table_objects[21], name: "status", value: "published"},
		# Properties for the fifth store book
	{table_object: table_objects[22], name: "collection", value: "921b2d9f-5565-442f-95c0-1658ee57146b"},
	{table_object: table_objects[22], name: "title", value: "1984"},
	{table_object: table_objects[22], name: "description", value: "Orwell's novel about the destruction of man by a perfect state machinery has long since become a metaphor for totalitarian conditions that no longer seems in need of explanation."},
	{table_object: table_objects[22], name: "language", value: "en"},
	{table_object: table_objects[22], name: "status", value: "published"},
		# Properties for the sixth store book
	{table_object: table_objects[23], name: "collection", value: "921b2d9f-5565-442f-95c0-1658ee57146b"},
	{table_object: table_objects[23], name: "title", value: "1984"},
	{table_object: table_objects[23], name: "description", value: "Orwells Roman über die Zerstörung des Menschen durch eine perfekte Staatsmaschinerie ist längst zu einer scheinbar nicht mehr erklärungsbedürftigen Metapher für totalitäre Verhältnisse geworden."},
	{table_object: table_objects[23], name: "language", value: "de"},
	{table_object: table_objects[23], name: "status", value: "review"},
		# Properties for the seventh store book
	{table_object: table_objects[24], name: "collection", value: "21a9045f-4148-4e21-a701-8d19dd865d17"},
	{table_object: table_objects[24], name: "title", value: "Animal Farm"},
	{table_object: table_objects[24], name: "description", value: "Animal Farm is an allegorical novella by George Orwell, first published in England on 17 August 1945. The book tells the story of a group of farm animals who rebel against their human farmer, hoping to create a society where the animals can be equal, free, and happy."},
	{table_object: table_objects[24], name: "language", value: "en"},
	{table_object: table_objects[24], name: "status", value: "published"}
])

notifications = Notification.create([
   # Time: 1863541331
   {user: users[4], app: apps.third, time: DateTime.parse("2029-01-19 18:22:11 +0000"), interval: 3600, uuid: "0289e7ab-5497-45dc-a6ad-d5d49143b17b"},
   # Time: 1806755643
   {user: users[4], app: apps.third, time: DateTime.parse("2027-04-03 12:34:03 +0000"), interval: 864000, uuid: "4590db9d-f154-42bc-aaa9-c222e3b82487"}
])

notification_properties = NotificationProperty.create([
	{notification: notifications.first, name: "title", value: "Hello World"},
	{notification: notifications.first, name: "message", value: "You have an appointment"},
	{notification: notifications.second, name: "title", value: "Your daily summary"},
	{notification: notifications.second, name: "message", value: "You have 2 appointments and one Todo for today"}
])

sessions = Session.create([
	# user: davClassLibraryTest, app: davClassLibraryTestApp
	# JWT: eyJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImRhdmNsYXNzbGlicmFyeXRlc3RAZGF2LWFwcHMudGVjaCIsInVzZXJfaWQiOjUsImRldl9pZCI6MiwiZXhwIjozNzU2MTA1MDAyMn0.jZpdLre_ZMWGN2VNbZOn2Xg51RLAT6ocGnyM38jljHI.1
	{user: users[4], app: apps[2], secret: "Pv99J1z5AcITJwi-kUVMTgKTj4EWD4bicoLPq2rT", exp: DateTime.parse("3160-04-06 09:00:22"), device_name: "Surface Book", device_type: "Laptop", device_os: "Windows 10"},
	# user: author, app: PocketLib
	# JWT: eyJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImF1dGhvckBkYXYtYXBwcy50ZWNoIiwidXNlcl9pZCI6NiwiZGV2X2lkIjoxLCJleHAiOjM3NTYxMDE3NjAwfQ.npXRbu87twmlyqBSPuGb1qOn7Mh1ug_j0qEQiLz3N6U.2
	{user: users[5], app: apps[5], secret: "incZClGp_gb8v6t20f9OS7hh7uIrveKjFCY-N0t4", exp: DateTime.parse("3160-04-06 00:00:00"), device_name: "Surface Neo", device_type: "Foldable", device_os: "Windows 10X"},
	# user: dav, app: PocketLib
	# JWT: eyJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImRhdkBkYXYtYXBwcy50ZWNoIiwidXNlcl9pZCI6MSwiZGV2X2lkIjoxLCJleHAiOjM3NTYxMDE3NjAwfQ.6LvizKcYttmWGLwGFS4A2nhSu6aOs8O9_pa2StxTQqE.3
	{user: users[0], app: apps[5], secret: "tTOwqee66k1-C549DKsU2Wbc4AQVg7Zyftj5z1vE", exp: DateTime.parse("3160-04-06 00:00:00"), device_name: "Surface Duo", device_type: "Foldable", device_os: "Android"},
	# user: davClassLibraryTest, app: PocketLib
	# JWT: eyJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImRhdkNsYXNzTGlicmFyeVRlc3RAZGF2LWFwcHMudGVjaCIsInVzZXJfaWQiOjUsImRldl9pZCI6MSwiZXhwIjozNzU2MTAxNzYwMH0.unJZtU7Mua12L_GsW09BvoeSQd56VR_RK9x3TE2GWQo.4
	{user: users[4], app: apps[5], secret: "82S0LIhhkPWQgRCFfrp92RuLxG3av-YpKZRyXIJm", exp: DateTime.parse("3160-04-06 00:00:00"), device_name: "Samsung Galaxy Book S", device_type: "Laptop", device_os: "Windows 10"}
])

apis = Api.create([
	{app: apps[5], name: "Pocketlib API v1"}
])