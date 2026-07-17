p = 'lib/screens/employee/employee_summary_screen.dart'
c = open(p, encoding='utf-8').read()
original = c

# 1) تصغير childAspectRatio للـ grids
# القديم childAspectRatio: 1.1 → 0.85 (يخلي الخانة أطول)
c = c.replace('childAspectRatio: 1.1,', 'childAspectRatio: 0.9,')

# 2) تصغير حجم الخط في _statBox لعدم الـ overflow
old_stat = '''Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),'''
new_stat = '''Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),'''
c = c.replace(old_stat, new_stat)

# 3) تصغير padding في _statBox
old_padding = '''padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),'''
new_padding = '''padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),'''
c = c.replace(old_padding, new_padding, 1)

# 4) تصغير label fontSize
old_label = '''Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),'''
new_label = '''Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),'''
c = c.replace(old_label, new_label)

# 5) إضافة maxLines للـ value
old_value = '''Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),'''
new_value = '''FittedBox(fit: BoxFit.scaleDown, child: Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))),'''
c = c.replace(old_value, new_value)

open(p, 'w', encoding='utf-8').write(c)
print('Fixed overflow issues')
print('Changed:', c != original)