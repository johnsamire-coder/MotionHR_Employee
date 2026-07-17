with open(r'lib\widgets\attachments_widget.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('class AttachmentsWidget')
print(content[idx:idx+500])