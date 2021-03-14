users = User.create([
	{email: "dav@dav-apps.tech", password: "davdavdav", username: "Dav", confirmed: true},
	{email: "test@example.com", password: "loremipsum", username: "Tester", confirmed: true},
	{email: "author@dav-apps.tech", password: "books", username: "Author-Tester", confirmed: true},
	{email: "klaus.baudelaire@dav-apps.tech", password: "isadora", username: "Klaus", confirmed: true, plan: 2}
])

devs = Dev.create([
	{user: users[0], api_key: "eUzs3PQZYweXvumcWvagRHjdUroGe5Mo7kN1inHm", secret_key: "Stac8pRhqH0CSO5o9Rxqjhu7vyVp4PINEMJumqlpvRQai4hScADamQ", uuid: "d133e303-9dbb-47db-9531-008b20e5aae8"},
	{user: users[1], api_key: "MhKSDyedSw8WXfLk2hkXzmElsiVStD7C8JU3KNGp", secret_key: "5nyf0tRr0GNmP3eB83pobm8hifALZsUq3NpW5En9nFRpssXxlZv-JA", uuid: "71a5d4f8-083e-413e-a8ff-66847a5f3a97"}
])

providers = Provider.create([
	{user: users[1], stripe_account_id: "acct_1GPFIgAwAxz84qLO"}
])

apps = App.create([
	{dev: devs[0], name: "dav Website", description: "This is the app for the dav website", published: false},
	{dev: devs[0], name: "UniversalSoundboard", description: "UniversalSoundboard is a customizable soundboard and music player", published: true},
	{dev: devs[0], name: "Calendo", description: "Calendo is a simple app for managing your todos and appointments", published: true},
	{dev: devs[0], name: "PocketLib", description: "PocketLib is the library in your pocket", published: true},
	{dev: devs[1], name: "TestApp", description: "This is an app for testing", published: true}
])

tables = Table.create([
	# UniversalSoundboard tables
	{name: "Sound", app: apps[1]},
	{name: "SoundFile", app: apps[1]},
	{name: "ImageFile", app: apps[1]},
	{name: "Category", app: apps[1]},
	{name: "PlayingSound", app: apps[1]},
	{name: "Order", app: apps[1]},
	# Calendo tables
	{name: "TodoList", app: apps[2]},
   {name: "Todo", app: apps[2]},
   {name: "Appointment", app: apps[2]},
	# PocketLib tables
	{name: "Book", app: apps[3]},
   {name: "BookFile", app: apps[3]},
   {name: "EpubBookmark", app: apps[3]},
	{name: "Settings", app: apps[3]},
	{name: "Author", app: apps[3]},
	{name: "AuthorBio", app: apps[3]},
	{name: "AuthorProfileImage", app: apps[3]},
	{name: "StoreBookCollection", app: apps[3]},
	{name: "StoreBookCollectionName", app: apps[3]},
	{name: "StoreBook", app: apps[3]},
	{name: "StoreBookCover", app: apps[3]},
	{name: "StoreBookFile", app: apps[3]},
	{name: "Category", app: apps[3]},
	{name: "CategoryName", app: apps[3]},
	# TestApp tables
	{name: "FirstTestTable", app: apps[4]},
	{name: "SecondTestTable", app: apps[4]}
])

