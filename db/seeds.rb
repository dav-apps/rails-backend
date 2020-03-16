users = User.create([
   {email: "dav@dav-apps.tech", password: "davdavdav", username: "Dav", confirmed: true},
   {email: "test@example.com", password: "password", username: "testuser", confirmed: true},
   {email: "nutzer@testemail.com", password: "blablablablabla", username: "nutzer", confirmed: false},
   {email: "normalo@helloworld.net", password: "schoeneheilewelt", username: "normalo", confirmed: true},
	{email: "davClassLibraryTest@dav-apps.tech", password: "davClassLibrary", username: "davClassLibraryTestUser", confirmed: true},
	{email: "author@dav-apps.tech", password: "books", username: "PocketLib Author tester", confirmed: true},
	{email: "klaus.baudelaire@dav-apps.tech", password: "isadora", username: "Klaus", confirmed: true, plan: 2}
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
	{name: "AuthorBio", app: apps[5]},
	{name: "AuthorProfileImage", app: apps[5]},
	{name: "StoreBookCollection", app: apps[5]},
	{name: "StoreBookCollectionName", app: apps[5]},
	{name: "StoreBook", app: apps[5]},
	{name: "StoreBookCover", app: apps[5]},
	{name: "StoreBookFile", app: apps[5]},
	{name: "Category", app: apps[5]},
	{name: "CategoryName", app: apps[5]}
])

table_objects = TableObject.create([
	{table: tables[2], user: users[4], uuid: "642e6407-f357-4e03-b9c2-82f754931161", file: false},
   {table: tables[2], user: users[4], uuid: "8d29f002-9511-407b-8289-5ebdcb5a5559", file: false},
	{table: tables[3], user: users[4], uuid: "4c8513e8-67c3-4067-8d80-bc2ed0459918", file: true},
	# Books
	{table: tables[13], user: users[6], uuid: "916b7ba2-db45-4c49-bef6-a90280efc686", file: false},
	# Authors
	{table: tables[18], user: users[5], uuid: "099fbfa5-a6f1-41c1-99e9-0d02d8364f2d", file: false},
	{table: tables[18], user: users[0], uuid: "622ad623-b9a4-415d-92ee-a66f8a7f3c51", file: false},
	{table: tables[18], user: users[0], uuid: "1dd980fd-ae20-4566-b842-a25e241bfb46", file: false},
	# AuthorBios
		# First bio of the first author
	{table: tables[19], user: users[5], uuid: "0d13e998-1b34-46be-90af-76c401f10fe2", file: false},
		# Second bio of the first author
	{table: tables[19], user: users[5], uuid: "51e8135e-7ba7-4d59-8f93-2eda6141dfc8", file: false},
		# First bio of the second author
	{table: tables[19], user: users[0], uuid: "8d394726-6398-4915-a042-33520f5f68cc", file: false},
		# First bio of the third author
	{table: tables[19], user: users[0], uuid: "cd940d1d-4006-4aff-a680-0cfa58ed63f1", file: false},
	# AuthorProfileImages
	{table: tables[20], user: users[5], uuid: "14e5ad81-3105-4cbc-85c8-4ffeec1c3812", file: true},
	{table: tables[20], user: users[0], uuid: "df45f27f-8ecb-41b0-864f-bb76669279f5", file: true},
	# StoreBookCollections
	{table: tables[21], user: users[5], uuid: "2cfe3d1a-2853-4e5c-9261-1942a9c5ddd9", file: false},
	{table: tables[21], user: users[5], uuid: "285a5fca-8db2-4f73-8b12-5d41cdac82ed", file: false},
	{table: tables[21], user: users[5], uuid: "7bb97f7e-cd7d-4fa8-a734-ef4732d33fcd", file: false},
	{table: tables[21], user: users[0], uuid: "921b2d9f-5565-442f-95c0-1658ee57146b", file: false},
	{table: tables[21], user: users[0], uuid: "21a9045f-4148-4e21-a701-8d19dd865d17", file: false},
	# StoreBookCollectionNames
		# First name of the first collection
	{table: tables[22], user: users[5], uuid: "5f0d68f0-fc99-457b-823a-b9994d17b6b1", file: false},
		# Second name of the first collection
	{table: tables[22], user: users[5], uuid: "f41d7646-b513-4af4-b93d-3813b1edfc3e", file: false},
		# First name of the second collection
	{table: tables[22], user: users[5], uuid: "9c2f12ad-0e94-4379-a0d6-7e087380bf5b", file: false},
		# Second name of the second collection
	{table: tables[22], user: users[5], uuid: "25060c42-e7bf-4187-9712-0a94c51d497c", file: false},
		# First name of the third collection
	{table: tables[22], user: users[5], uuid: "e5a21039-1aae-406b-98ba-16d820e906e7", file: false},
		# First name of the fourth collection
	{table: tables[22], user: users[0], uuid: "9ffb7b69-b9bc-45bc-ae94-34ec08c427c2", file: false},
		# First name of the fifth collection
	{table: tables[22], user: users[0], uuid: "5d8ebd0d-9e62-42bb-8565-963cbb6499d7", file: false},
	# StoreBooks
		# First book of the first collection
	{table: tables[23], user: users[5], uuid: "1cf6fc5f-8fa5-4972-895d-8b1d6552d41c", file: false},
		# Second book of the first collection
	{table: tables[23], user: users[5], uuid: "4df158a0-2157-4370-abac-dd3c25ca9ed3", file: false},
		# First book of the second collection
	{table: tables[23], user: users[5], uuid: "5242102c-b107-4e82-8eb8-bebe2a990436", file: false},
		# Second book of the second collection
	{table: tables[23], user: users[5], uuid: "617833c8-4d0a-4d78-acd0-306a90e346ba", file: false},
		# First book of the third collection
	{table: tables[23], user: users[5], uuid: "45c14ab4-8789-41c4-b0f6-11be0a86a94c", file: false},
		# Second book of the third collection
	{table: tables[23], user: users[5], uuid: "2fd1beed-da6f-46c8-8631-a7931dda2ef2", file: false},
		# First book of the fourth collection
	{table: tables[23], user: users[0], uuid: "b0e4b01d-d53d-47b5-b5e4-48ea7bab6619", file: false},
		# Second book of the fourth collection
	{table: tables[23], user: users[0], uuid: "5aa1c310-cbc6-48b4-9000-63315e713d25", file: false},
		# Third book of the fourth collection
	{table: tables[23], user: users[0], uuid: "0c3d12b8-1398-4f4e-b912-2aa460671579", file: false},
		# First book of the fifth collection
	{table: tables[23], user: users[0], uuid: "13836f22-040f-4efd-9f30-9202184b23bf", file: false},
		# Second book of the fifth collection
	{table: tables[23], user: users[0], uuid: "f27a4472-d3f8-4310-9f76-156af7c03c43", file: false},
		# Third book of the fifth collection
	{table: tables[23], user: users[0], uuid: "ba96f327-f096-4408-8bd0-620f9aad3f09", file: false},
	# StoreBookCovers
		# Covers for the first author
	{table: tables[24], user: users[5], uuid: "bb63e1c9-866c-47b5-b852-e8473df404f3", file: true},
	{table: tables[24], user: users[5], uuid: "2ba327c3-d33c-4181-900e-f4c331ddf288", file: true},
	{table: tables[24], user: users[5], uuid: "a557824f-26ed-4e5e-8afa-43e20e76e2ad", file: true},
	{table: tables[24], user: users[5], uuid: "33b486ae-a22e-414b-915c-9a9520970ed8", file: true},
	{table: tables[24], user: users[5], uuid: "c877a6e5-aebb-4c8c-b28d-817aaffc9226", file: true},
		# Covers for the second author
	{table: tables[24], user: users[0], uuid: "63960709-1aa5-40dd-a7a3-8fa79aaa1f5d", file: true},
	# StoreBookFiles
		# Files for the first author
	{table: tables[25], user: users[5], uuid: "b7cf0cee-fe8d-4f08-8b6e-d391065f1abb", file: true},
	{table: tables[25], user: users[5], uuid: "8f219b89-eb25-4c55-b1a4-467e36bfa081", file: true},
	{table: tables[25], user: users[5], uuid: "fb2745e4-f095-4237-97d5-660e41356790", file: true},
	{table: tables[25], user: users[5], uuid: "d6f52b96-6bca-40ee-bb70-fb1347e1c8ba", file: true},
	{table: tables[25], user: users[5], uuid: "090cb584-c10e-4068-9346-81f134c3a5e3", file: true},
		# Files for the second author
	{table: tables[25], user: users[0], uuid: "32adbdaa-0cbe-4672-80a6-19d4b8d6e943", file: true},
	{table: tables[25], user: users[0], uuid: "050f7a0d-59a9-498a-9caa-8b418227e72b", file: true},
	{table: tables[25], user: users[0], uuid: "6566a1b6-0b17-4ff8-ba01-c58374c179ee", file: true},
	{table: tables[25], user: users[0], uuid: "987335cf-4fd0-4c80-a6f1-97bedd46ecbf", file: true},
	# Categories
	{table: tables[26], user: users[0], uuid: "0d29f1a8-e181-448c-81d1-5000b167cb16", file: false},
	{table: tables[26], user: users[0], uuid: "8f1ac4ab-aeba-4e8a-8071-a2a77553dc3f", file: false},
	{table: tables[26], user: users[0], uuid: "27c78f90-934e-41e3-8738-b20f6d76f0a9", file: false},
	# CategoryNames
	{table: tables[27], user: users[0], uuid: "a6125ec6-085f-4da3-b5c8-991922ec2081", file: false},
	{table: tables[27], user: users[0], uuid: "b3cdf544-0485-48cf-a911-e7c187bcede5", file: false},
	{table: tables[27], user: users[0], uuid: "60b73b76-310e-494b-be1a-8d19e5caf630", file: false},
	{table: tables[27], user: users[0], uuid: "ce8f692d-5a4e-416a-8bb0-33802366db04", file: false},
	{table: tables[27], user: users[0], uuid: "029e6808-e328-4fe2-bddd-3a80606e25aa", file: false},
	{table: tables[27], user: users[0], uuid: "efaa516a-dd29-4fe4-aee1-25eabee3512a", file: false}
])

properties = Property.create([
	{table_object: table_objects[0], name: "page1", value: "Hello World"},
	{table_object: table_objects[0], name: "page2", value: "Hallo Welt"},
	{table_object: table_objects[1], name: "page1", value: "Table"},
	{table_object: table_objects[1], name: "page2", value: "Tabelle"},
	# Book properties
		# Properties for the first book
	{table_object: table_objects[3], name: "store_book", value: "b0e4b01d-d53d-47b5-b5e4-48ea7bab6619"},
	{table_object: table_objects[3], name: "file", value: "32adbdaa-0cbe-4672-80a6-19d4b8d6e943"},
	# Author properties
		# Properties for the first author
	{table_object: table_objects[4], name: "first_name", value: "Lemony"},
	{table_object: table_objects[4], name: "last_name", value: "Snicket"},
	{table_object: table_objects[4], name: "bios", value: "0d13e998-1b34-46be-90af-76c401f10fe2,51e8135e-7ba7-4d59-8f93-2eda6141dfc8"},
	{table_object: table_objects[4], name: "collections", value: "2cfe3d1a-2853-4e5c-9261-1942a9c5ddd9,285a5fca-8db2-4f73-8b12-5d41cdac82ed,7bb97f7e-cd7d-4fa8-a734-ef4732d33fcd"},
	{table_object: table_objects[4], name: "profile_image", value: "14e5ad81-3105-4cbc-85c8-4ffeec1c3812"},
		# Properties for the second author
	{table_object: table_objects[5], name: "first_name", value: "George"},
	{table_object: table_objects[5], name: "last_name", value: "Orwell"},
	{table_object: table_objects[5], name: "bios", value: "8d394726-6398-4915-a042-33520f5f68cc"},
	{table_object: table_objects[5], name: "collections", value: "921b2d9f-5565-442f-95c0-1658ee57146b,21a9045f-4148-4e21-a701-8d19dd865d17"},
	{table_object: table_objects[5], name: "profile_image", value: "df45f27f-8ecb-41b0-864f-bb76669279f5"},
		# Properties for the third author
	{table_object: table_objects[6], name: "first_name", value: "Aldous"},
	{table_object: table_objects[6], name: "last_name", value: "Huxley"},
	{table_object: table_objects[6], name: "bios", value: "cd940d1d-4006-4aff-a680-0cfa58ed63f1"},
	# AuthorBio properties
		# Properties for the first bio
	{table_object: table_objects[7], name: "bio", value: "Dear reader, I'm sorry to tell you that I wrote some very unpleasant tales that you definitely should not read, if you want to further live a healthy life."},
	{table_object: table_objects[7], name: "language", value: "en"},
		# Properties for the second bio
	{table_object: table_objects[8], name: "bio", value: "Lieber Leser, es tut mir Leid, dir sagen zu müssen, dass ich einige sehr unangenehme Geschichten geschrieben habe, die du auf keinen Fall lesen solltest, wenn du weiterhin ein gesundes Leben führen willst."},
	{table_object: table_objects[8], name: "language", value: "de"},
		# Properties for the third bio
	{table_object: table_objects[9], name: "bio", value: "Eric Arthur Blair, better known by his pen name George Orwell, was an English novelist and essayist, journalist and critic. His work is characterised by lucid prose, awareness of social injustice, opposition to totalitarianism, and outspoken support of democratic socialism."},
	{table_object: table_objects[9], name: "language", value: "en"},
		# Properties for the fourth bio
	{table_object: table_objects[10], name: "bio", value: "Aldous Leonard Huxley was an English writer and philosopher. He wrote nearly fifty books — both novels and non-fiction works — as well as wide-ranging essays, narratives, and poems."},
	{table_object: table_objects[10], name: "language", value: "en"},
	# AuthorProfileImage properties
		# Properties for the first AuthorProfileImage
	{table_object: table_objects[11], name: "ext", value: "png"},
	{table_object: table_objects[11], name: "type", value: "image/png"},
		# Properties for the second AuthorProfileImage
	{table_object: table_objects[12], name: "ext", value: "jpg"},
	{table_object: table_objects[12], name: "type", value: "image/jpeg"},
	# StoreBookCollection properties
		# Properties for the first collection
	{table_object: table_objects[13], name: "author", value: "099fbfa5-a6f1-41c1-99e9-0d02d8364f2d"},
	{table_object: table_objects[13], name: "names", value: "5f0d68f0-fc99-457b-823a-b9994d17b6b1,f41d7646-b513-4af4-b93d-3813b1edfc3e"},
	{table_object: table_objects[13], name: "books", value: "1cf6fc5f-8fa5-4972-895d-8b1d6552d41c,4df158a0-2157-4370-abac-dd3c25ca9ed3"},
		# Properties for the second collection
	{table_object: table_objects[14], name: "author", value: "099fbfa5-a6f1-41c1-99e9-0d02d8364f2d"},
	{table_object: table_objects[14], name: "names", value: "9c2f12ad-0e94-4379-a0d6-7e087380bf5b,25060c42-e7bf-4187-9712-0a94c51d497c"},
	{table_object: table_objects[14], name: "books", value: "5242102c-b107-4e82-8eb8-bebe2a990436,617833c8-4d0a-4d78-acd0-306a90e346ba"},
		# Properties for the third collection
	{table_object: table_objects[15], name: "author", value: "099fbfa5-a6f1-41c1-99e9-0d02d8364f2d"},
	{table_object: table_objects[15], name: "names", value: "e5a21039-1aae-406b-98ba-16d820e906e7"},
	{table_object: table_objects[15], name: "books", value: "45c14ab4-8789-41c4-b0f6-11be0a86a94c"},
		# Properties for the fourth collection
	{table_object: table_objects[16], name: "author", value: "622ad623-b9a4-415d-92ee-a66f8a7f3c51"},
	{table_object: table_objects[16], name: "names", value: "9ffb7b69-b9bc-45bc-ae94-34ec08c427c2"},
	{table_object: table_objects[16], name: "books", value: "b0e4b01d-d53d-47b5-b5e4-48ea7bab6619,5aa1c310-cbc6-48b4-9000-63315e713d25,0c3d12b8-1398-4f4e-b912-2aa460671579"},
		# Properties for the fifth collection
	{table_object: table_objects[17], name: "author", value: "622ad623-b9a4-415d-92ee-a66f8a7f3c51"},
	{table_object: table_objects[17], name: "names", value: "5d8ebd0d-9e62-42bb-8565-963cbb6499d7"},
	{table_object: table_objects[17], name: "books", value: "13836f22-040f-4efd-9f30-9202184b23bf,f27a4472-d3f8-4310-9f76-156af7c03c43,ba96f327-f096-4408-8bd0-620f9aad3f09"},
	# StoreBookCollectionName properties
		# Properties for the first collection name
	{table_object: table_objects[18], name: "name", value: "A Series of Unfortunate Events - Book the First"},
	{table_object: table_objects[18], name: "language", value: "en"},
		# Properties for the second collection name
	{table_object: table_objects[19], name: "name", value: "Eine Reihe betrüblicher Ereignisse - Der schreckliche Anfang"},
	{table_object: table_objects[19], name: "language", value: "de"},
		# Properties for the third collection name
	{table_object: table_objects[20], name: "name", value: "A Series of Unfortunate Events - Book the Second"},
	{table_object: table_objects[20], name: "language", value: "en"},
		# Properties for the fourth collection name
	{table_object: table_objects[21], name: "name", value: "Eine Reihe betrüblicher Ereignisse - Das Haus der Schlangen"},
	{table_object: table_objects[21], name: "language", value: "de"},
		# Properties for the fifth collection name
	{table_object: table_objects[22], name: "name", value: "A Series of Unfortunate Events - Book the Third"},
	{table_object: table_objects[22], name: "language", value: "en"},
		# Properties for the sixth collection name
	{table_object: table_objects[23], name: "name", value: "1984"},
	{table_object: table_objects[23], name: "language", value: "en"},
		# Properties for the seventh collection name
	{table_object: table_objects[24], name: "name", value: "Animal Farm"},
	{table_object: table_objects[24], name: "language", value: "en"},
	# StoreBook properties
		# Properties for the first store book
	{table_object: table_objects[25], name: "collection", value: "2cfe3d1a-2853-4e5c-9261-1942a9c5ddd9"},
	{table_object: table_objects[25], name: "title", value: "A Series of Unfortunate Events - Book the First"},
	{table_object: table_objects[25], name: "description", value: "Dear Reader, I'm sorry to say that the book you are holding in your hands is extremely unpleasant. It tells an unhappy tale about three very unlucky children."},
	{table_object: table_objects[25], name: "language", value: "en"},
	{table_object: table_objects[25], name: "price", value: "1399"},
	{table_object: table_objects[25], name: "status", value: "review"},
	{table_object: table_objects[25], name: "cover", value: "bb63e1c9-866c-47b5-b852-e8473df404f3"},
	{table_object: table_objects[25], name: "file", value: "b7cf0cee-fe8d-4f08-8b6e-d391065f1abb"},
		# Properties for the second store book
	{table_object: table_objects[26], name: "collection", value: "2cfe3d1a-2853-4e5c-9261-1942a9c5ddd9"},
	{table_object: table_objects[26], name: "title", value: "Eine Reihe betrüblicher Ereignisse - Der schreckliche Anfang"},
	{table_object: table_objects[26], name: "description", value: "Lieber Leser, es tut mir sehr Leid, aber das Buch, das du gerade in Händen hältst, ist außerordentlich unerfreulich. Es erzählt die traurige Geschichte von drei sehr bedauernswerten Kindern."},
	{table_object: table_objects[26], name: "language", value: "de"},
	{table_object: table_objects[26], name: "status", value: "hidden"},
	{table_object: table_objects[26], name: "cover", value: "2ba327c3-d33c-4181-900e-f4c331ddf288"},
	{table_object: table_objects[26], name: "file", value: "8f219b89-eb25-4c55-b1a4-467e36bfa081"},
		# Properties for the third store book
	{table_object: table_objects[27], name: "collection", value: "285a5fca-8db2-4f73-8b12-5d41cdac82ed"},
	{table_object: table_objects[27], name: "title", value: "A Series of Unfortunate Events - Book the Second"},
	{table_object: table_objects[27], name: "description", value: "Dear Reader, if you have picked up this book with the hope of finding a simple and cheery tale, I'm afraid you have picked up the wrong book altogether."},
	{table_object: table_objects[27], name: "language", value: "en"},
	{table_object: table_objects[27], name: "status", value: "unpublished"},
	{table_object: table_objects[27], name: "cover", value: "a557824f-26ed-4e5e-8afa-43e20e76e2ad"},
	{table_object: table_objects[27], name: "file", value: "fb2745e4-f095-4237-97d5-660e41356790"},
		# Properties for the fourth store book
	{table_object: table_objects[28], name: "collection", value: "285a5fca-8db2-4f73-8b12-5d41cdac82ed"},
	{table_object: table_objects[28], name: "title", value: "Eine Reihe betrüblicher Ereignisse - Das Haus der Schlangen"},
	{table_object: table_objects[28], name: "description", value: "Lieber Leser, wenn du dieses Buch zur Hand genommen hast in der Hoffnung, darin Zerstreuung und Vergnügen zu finden, dann liegst du leider völlig falsch."},
	{table_object: table_objects[28], name: "language", value: "de"},
	{table_object: table_objects[28], name: "price", value: "2000"},
	{table_object: table_objects[28], name: "status", value: "published"},
	{table_object: table_objects[28], name: "cover", value: "33b486ae-a22e-414b-915c-9a9520970ed8"},
	{table_object: table_objects[28], name: "file", value: "d6f52b96-6bca-40ee-bb70-fb1347e1c8ba"},
		# Properties for the fifth store book
	{table_object: table_objects[29], name: "collection", value: "7bb97f7e-cd7d-4fa8-a734-ef4732d33fcd"},
	{table_object: table_objects[29], name: "title", value: "A Series of Unfortunate Events - Book the Third"},
	{table_object: table_objects[29], name: "description", value: "Dear Reader, if you have not read anything about the Baudelaire orphans, then before you read even one more sentence, you should know this: Violet, Klaus and Sunny are kindhearted and quick-witted, but their lives, I am sorry to say, are filled with bad luck and misery."},
	{table_object: table_objects[29], name: "language", value: "en"},
	{table_object: table_objects[29], name: "status", value: "unpublished"},
		# Properties for the sixth store book
	{table_object: table_objects[30], name: "collection", value: "7bb97f7e-cd7d-4fa8-a734-ef4732d33fcd"},
	{table_object: table_objects[30], name: "title", value: "Eine Reihe betrüblicher Ereignisse - Der Seufzersee"},
	{table_object: table_objects[30], name: "description", value: "Lieber Leser, wenn du noch nie etwas von den Baudelaire-Kindern gehört hast, dann solltest du, bevor du auch nur eine einzige Zeile liest, Folgendes wissen: Violet, Klaus und Sunny sind nett, charmant und klug, aber ihr Leben - leider, leider - strotzt nur so vor Elend und Unheil."},
	{table_object: table_objects[30], name: "language", value: "en"},
	{table_object: table_objects[30], name: "status", value: "published"},
	{table_object: table_objects[30], name: "cover", value: "c877a6e5-aebb-4c8c-b28d-817aaffc9226"},
	{table_object: table_objects[30], name: "file", value: "090cb584-c10e-4068-9346-81f134c3a5e3"},
		# Properties for the seventh store book
	{table_object: table_objects[31], name: "collection", value: "921b2d9f-5565-442f-95c0-1658ee57146b"},
	{table_object: table_objects[31], name: "title", value: "1984"},
	{table_object: table_objects[31], name: "description", value: "Orwell's novel about the destruction of man by a perfect state machinery has long since become a metaphor for totalitarian conditions that no longer seems in need of explanation."},
	{table_object: table_objects[31], name: "language", value: "en"},
	{table_object: table_objects[31], name: "price", value: "1000"},
	{table_object: table_objects[31], name: "status", value: "published"},
	{table_object: table_objects[31], name: "cover", value: "63960709-1aa5-40dd-a7a3-8fa79aaa1f5d"},
	{table_object: table_objects[31], name: "file", value: "32adbdaa-0cbe-4672-80a6-19d4b8d6e943"},
		# Properties for the eighth store book
	{table_object: table_objects[32], name: "collection", value: "921b2d9f-5565-442f-95c0-1658ee57146b"},
	{table_object: table_objects[32], name: "title", value: "1984"},
	{table_object: table_objects[32], name: "description", value: "Orwells Roman über die Zerstörung des Menschen durch eine perfekte Staatsmaschinerie ist längst zu einer scheinbar nicht mehr erklärungsbedürftigen Metapher für totalitäre Verhältnisse geworden."},
	{table_object: table_objects[32], name: "language", value: "de"},
	{table_object: table_objects[32], name: "status", value: "review"},
	{table_object: table_objects[32], name: "file", value: "050f7a0d-59a9-498a-9caa-8b418227e72b"},
		# Properties for the ninth store book
	{table_object: table_objects[33], name: "collection", value: "921b2d9f-5565-442f-95c0-1658ee57146b"},
	{table_object: table_objects[33], name: "title", value: "1984"},
	{table_object: table_objects[33], name: "description", value: "Le roman d'Orwell sur la destruction de l'homme par une machine étatique parfaite est devenu depuis longtemps une métaphore des conditions totalitaires qui ne semble plus avoir besoin d'explication."},
	{table_object: table_objects[33], name: "language", value: "fr"},
	{table_object: table_objects[33], name: "status", value: "unpublished"},
		# Properties for the tenth store book
	{table_object: table_objects[34], name: "collection", value: "21a9045f-4148-4e21-a701-8d19dd865d17"},
	{table_object: table_objects[34], name: "title", value: "Animal Farm"},
	{table_object: table_objects[34], name: "description", value: "Animal Farm is an allegorical novella by George Orwell, first published in England on 17 August 1945. The book tells the story of a group of farm animals who rebel against their human farmer, hoping to create a society where the animals can be equal, free, and happy."},
	{table_object: table_objects[34], name: "language", value: "en"},
	{table_object: table_objects[34], name: "status", value: "hidden"},
	{table_object: table_objects[34], name: "file", value: "6566a1b6-0b17-4ff8-ba01-c58374c179ee"},
		# Properties for the eleventh store book
	{table_object: table_objects[35], name: "collection", value: "21a9045f-4148-4e21-a701-8d19dd865d17"},
	{table_object: table_objects[35], name: "title", value: "Farm der Tiere"},
	{table_object: table_objects[35], name: "description", value: "Farm der Tiere ist eine allegorische Novelle von George Orwell, die erstmals am 17. August 1945 in England veröffentlicht wurde. Das Buch erzählt die Geschichte einer Gruppe von Nutztieren, die sich gegen ihren menschlichen Bauern auflehnen, in der Hoffnung, eine Gesellschaft zu schaffen, in der die Tiere gleichberechtigt, frei und glücklich sein können."},
	{table_object: table_objects[35], name: "language", value: "de"},
	{table_object: table_objects[35], name: "file", value: "987335cf-4fd0-4c80-a6f1-97bedd46ecbf"},
		# Properties for the twelfth store book
	{table_object: table_objects[36], name: "collection", value: "21a9045f-4148-4e21-a701-8d19dd865d17"},
	{table_object: table_objects[36], name: "title", value: "La Ferme des animaux"},
	{table_object: table_objects[36], name: "description", value: "La Ferme des animaux est un roman allégorique de George Orwell, publié pour la première fois en Angleterre le 17 août 1945. Le livre raconte l'histoire d'un groupe d'animaux de ferme qui se rebellent contre leur éleveur humain dans l'espoir de créer une société dans laquelle les animaux peuvent être égaux, libres et heureux."},
	{table_object: table_objects[36], name: "language", value: "fr"},
	{table_object: table_objects[36], name: "status", value: "published"},
	# StoreBookCover properties
		# Properties for the first StoreBookCover
	{table_object: table_objects[37], name: "ext", value: "png"},
	{table_object: table_objects[37], name: "type", value: "image/png"},
		# Properties for the second StoreBookCover
	{table_object: table_objects[38], name: "ext", value: "jpg"},
	{table_object: table_objects[38], name: "type", value: "image/jpeg"},
		# Properties for the third StoreBookCover
	{table_object: table_objects[39], name: "ext", value: "png"},
	{table_object: table_objects[39], name: "type", value: "image/png"},
		# Properties for the fourth StoreBookCover
	{table_object: table_objects[40], name: "ext", value: "jpg"},
	{table_object: table_objects[40], name: "type", value: "image/jpeg"},
		# Properties for the fifth StoreBookCover
	{table_object: table_objects[41], name: "ext", value: "png"},
	{table_object: table_objects[41], name: "type", value: "image/png"},
		# Properties for the sixth StoreBookCover
	{table_object: table_objects[42], name: "ext", value: "jpg"},
	{table_object: table_objects[42], name: "type", value: "image/jpeg"},
	# StoreBookFile properties
		# Properties for the first StoreBookFile
	{table_object: table_objects[43], name: "ext", value: "pdf"},
	{table_object: table_objects[43], name: "type", value: "application/pdf"},
		# Properties for the second StoreBookFile
	{table_object: table_objects[44], name: "ext", value: "epub"},
	{table_object: table_objects[44], name: "type", value: "application/zip+epub"},
		# Properties for the third StoreBookFile
	{table_object: table_objects[45], name: "ext", value: "pdf"},
	{table_object: table_objects[45], name: "type", value: "application/pdf"},
		# Properties for the fourth StoreBookFile
	{table_object: table_objects[46], name: "ext", value: "epub"},
	{table_object: table_objects[46], name: "type", value: "application/zip+epub"},
		# Properties for the fifth StoreBookFile
	{table_object: table_objects[47], name: "ext", value: "pdf"},
	{table_object: table_objects[47], name: "type", value: "application/pdf"},
		# Properties for the sixth StoreBookFile
	{table_object: table_objects[48], name: "ext", value: "pdf"},
	{table_object: table_objects[48], name: "type", value: "application/pdf"},
		# Properties for the seventh StoreBookFile
	{table_object: table_objects[49], name: "ext", value: "epub"},
	{table_object: table_objects[49], name: "type", value: "application/zip+epub"},
		# Properties for the eighth StoreBookFile
	{table_object: table_objects[50], name: "ext", value: "pdf"},
	{table_object: table_objects[50], name: "type", value: "application/pdf"},
		# Properties for the ninth StoreBookFile
	{table_object: table_objects[51], name: "ext", value: "epub"},
	{table_object: table_objects[51], name: "type", value: "application/zip+epub"},
	# Category properties
		# Properties for the first category
	{table_object: table_objects[52], name: "key", value: "childrens"},
	{table_object: table_objects[52], name: "names", value: "a6125ec6-085f-4da3-b5c8-991922ec2081,b3cdf544-0485-48cf-a911-e7c187bcede5"},
		# Properties for the second category
	{table_object: table_objects[53], name: "key", value: "tragedy"},
	{table_object: table_objects[53], name: "names", value: "60b73b76-310e-494b-be1a-8d19e5caf630,ce8f692d-5a4e-416a-8bb0-33802366db04"},
		# Properties for the third category
	{table_object: table_objects[54], name: "key", value: "dystopia"},
	{table_object: table_objects[54], name: "names", value: "029e6808-e328-4fe2-bddd-3a80606e25aa,efaa516a-dd29-4fe4-aee1-25eabee3512a"},
	# CategoryName properties
		# Properties for the first name of the first category
	{table_object: table_objects[55], name: "name", value: "Children's book"},
	{table_object: table_objects[55], name: "language", value: "en"},
		# Properties for the second name of the first category
	{table_object: table_objects[56], name: "name", value: "Kinderbuch"},
	{table_object: table_objects[56], name: "language", value: "de"},
		# Properties for the first name of the second category
	{table_object: table_objects[57], name: "name", value: "Tragedy"},
	{table_object: table_objects[57], name: "language", value: "en"},
		# Properties for the second name of the second category
	{table_object: table_objects[58], name: "name", value: "Tragödie"},
	{table_object: table_objects[58], name: "language", value: "de"},
		# Properties for the first name of the third category
	{table_object: table_objects[59], name: "name", value: "Dystopia"},
	{table_object: table_objects[59], name: "language", value: "en"},
		# Properties for the second name of the third category
	{table_object: table_objects[60], name: "name", value: "Dystopie"},
	{table_object: table_objects[60], name: "language", value: "de"}
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
	{user: users[4], app: apps[5], secret: "82S0LIhhkPWQgRCFfrp92RuLxG3av-YpKZRyXIJm", exp: DateTime.parse("3160-04-06 00:00:00"), device_name: "Samsung Galaxy Book S", device_type: "Laptop", device_os: "Windows 10"},
	# user: Klaus, app: PocketLib
	# JWT: eyJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImtsYXVzLmJhdWRlbGFpcmVAZGF2LWFwcHMudGVjaCIsInVzZXJfaWQiOjcsImRldl9pZCI6MSwiZXhwIjozNzU2MTAxNzYwMH0.Ow0dLs1x_HR6fJ02UqQBVRxDME7cqp_4LRxioJfe_F4.5
	{user: users[6], app: apps[5], secret: "22KPAM9RIJnAE2TYb47IQN_QG6mEBq9kxV8gmRAx", exp: DateTime.parse("3160-04-06 00:00:00"), device_name: "PocketBook", device_type: "Book", device_os: "Windows Core"}
])

apis = Api.create([
	{app: apps[5], name: "Pocketlib API v1"}
])