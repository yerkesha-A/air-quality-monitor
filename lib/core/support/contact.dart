const supportEmail = 'erkezhanabdraim@gmail.com';

Uri accountDeletionEmail() {
  final fields = {
    'subject': 'Удаление аккаунта Air Quality Monitor',
    'body': 'Здравствуйте! Прошу удалить мой аккаунт Air Quality Monitor и связанные облачные данные.\n\nEmail моего аккаунта: \n\nПароль и коды подтверждения не прилагаю.',
  };
  return Uri.parse(
    'mailto:$supportEmail?${fields.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}',
  );
}
