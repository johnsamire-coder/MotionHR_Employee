p = 'lib/main.dart'
c = open(p, encoding='utf-8-sig').read()

old = """const NotificationBellButton(),
            IconButton(
              icon: const Icon(Icons.lock),"""

new = """const NotificationBellButton(),
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'الملف الشخصي',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeProfileScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.lock),"""

if old in c:
    n = c.replace(old, new, 1)
    open(p, 'w', encoding='utf-8-sig').write(n)
    print('SUCCESS - button added')
else:
    print('OLD NOT FOUND - checking...')
    print('has NotificationBellButton:', 'NotificationBellButton' in c)
    print('has Icons.lock:', 'Icons.lock' in c)