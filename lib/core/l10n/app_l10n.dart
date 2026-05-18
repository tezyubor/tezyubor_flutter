import 'package:flutter/widgets.dart';

class AppL10n {
  final String code;
  const AppL10n._(this.code);

  static const _ru = AppL10n._('ru');
  static const _uz = AppL10n._('uz');
  static const _en = AppL10n._('en');

  static AppL10n fromCode(String? code) => switch (code) {
        'uz' => _uz,
        'en' => _en,
        _ => _ru,
      };

  String _t(String ru, String uz, String en) => switch (code) {
        'uz' => uz,
        'en' => en,
        _ => ru,
      };

  // Navigation
  String get orders => _t('Заказы', 'Buyurtmalar', 'Orders');
  String get analytics => _t('Аналитика', 'Analitika', 'Analytics');
  String get clients => _t('Клиенты', 'Mijozlar', 'Clients');
  String get settings => _t('Настройки', 'Sozlamalar', 'Settings');
  String get profile => _t('Профиль', 'Profil', 'Profile');

  // Subscription blocking modal
  String get subscriptionExpiredTitle => _t('Подписка истекла', 'Obuna tugadi', 'Subscription expired');
  String get subscriptionExpiredMsg => _t(
    'Ваша подписка истекла. Продлите доступ, чтобы продолжить работу.',
    "Obunangiz tugadi. Davom etish uchun obunani yangilang.",
    'Your subscription has expired. Renew access to continue.',
  );
  String get renewSubscription => _t("Оплатить подписку", "Obunani to'lash", 'Pay subscription');
  String get subscriptionPrice => _t('100 000 сум / месяц', "100 000 so'm / oy", '100,000 UZS / month');
  String get subscriptionPayError => _t('Не удалось создать платёж', "To'lov yaratib bo'lmadi", 'Failed to create payment');

  // Common
  String get save => _t('Сохранить', 'Saqlash', 'Save');
  String get cancel => _t('Отмена', 'Bekor qilish', 'Cancel');
  String get yes => _t('Да', 'Ha', 'Yes');
  String get no => _t('Нет', "Yo'q", 'No');
  String get close => _t('Закрыть', 'Yopish', 'Close');
  String get confirm => _t('Подтвердить', 'Tasdiqlash', 'Confirm');
  String get logout => _t('Выйти', 'Chiqish', 'Log out');
  String get search => _t('Поиск', 'Qidirish', 'Search');
  String get filter => _t('Фильтр', 'Filtr', 'Filter');
  String get apply => _t('Применить', "Qo'llash", 'Apply');
  String get clear => _t('Сбросить', 'Tozalash', 'Clear');
  String get retry => _t('Повторить', 'Qayta', 'Retry');
  String get from => _t('От', 'Dan', 'From');
  String get to => _t('До', 'Gacha', 'To');
  String get all => _t('Все', 'Hammasi', 'All');
  String get error => _t('Ошибка', 'Xatolik', 'Error');
  String get success => _t('Успешно', 'Muvaffaqiyatli', 'Success');

  // Auth
  String get loginTitle => _t('Вход в аккаунт', 'Hisobga kirish', 'Sign In');
  String get adminLoginTitle =>
      _t('Вход для администратора', 'Admin kirishi', 'Admin Sign In');
  String get loginHint =>
      _t('Введите логин и пароль', 'Login va parolni kiriting', 'Enter credentials');
  String get loginBtn => _t('Войти', 'Kirish', 'Sign In');
  String get quickDelivery =>
      _t('Быстрая доставка товаров', "Tez yetkazib berish", 'Fast delivery');

  // Orders
  String get newOrder => _t('Новый заказ', 'Yangi buyurtma', 'New Order');
  String get order => _t('Заказ', 'Buyurtma', 'Order');
  String get deleteProfile => _t('Удалить профиль', 'Profilni o\'chirish', 'Delete Profile');
  String get deleteProfileConfirm => _t(
    'Это действие необратимо. Все данные вашего профиля, заказы и история будут удалены.',
    'Bu amalni qaytarib bo\'lmaydi. Profilingiz, buyurtmalar va tarix o\'chiriladi.',
    'This is irreversible. Your profile, orders and history will be permanently deleted.',
  );
  String get deleteProfileError => _t('Не удалось удалить профиль', 'Profilni o\'chirib bo\'lmadi', 'Failed to delete profile');
  String get createOrder => _t('Создать заказ', 'Buyurtma yaratish', 'Create Order');
  String get orderDetail =>
      _t('Детали заказа', 'Buyurtma tafsilotlari', 'Order Details');
  String get medicines => _t('Лекарства', 'Dorilar', 'Medicines');
  String get deliveryCost =>
      _t('Доставка', 'Yetkazib berish', 'Delivery');
  String get totalCost => _t('Итого', 'Jami', 'Total');
  String get courier => _t('Курьер', 'Kuryer', 'Courier');
  String get trackingLink =>
      _t('Ссылка отслеживания', 'Kuzatuv havolasi', 'Tracking Link');
  String get noOrders => _t('Нет заказов', "Buyurtmalar yo'q", 'No orders');
  String get createFirstOrder =>
      _t('Создайте первый заказ', 'Birinchi buyurtmani yarating', 'Create your first order');
  String get cancelOrderTitle =>
      _t('Отменить заказ?', 'Buyurtmani bekor qilasizmi?', 'Cancel order?');
  String get cancelOrderMsg =>
      _t('Это действие нельзя отменить.', "Bu amal qaytarib bo'lmaydi.", 'This cannot be undone.');
  String get orderConfirmed =>
      _t('Заказ подтверждён', 'Buyurtma tasdiqlandi', 'Order confirmed');
  String get orderCancelled =>
      _t('Заказ отменён', 'Buyurtma bekor qilindi', 'Order cancelled');
  String get statusFilter =>
      _t('Фильтр по статусу', "Holat bo'yicha filtr", 'Filter by status');
  String get dateRange => _t('Период', "Sana oralig'i", 'Date range');
  String get createdAt => _t('Создан', 'Yaratilgan', 'Created');
  String get customer => _t('Клиент', 'Mijoz', 'Customer');
  String get address => _t('Адрес', 'Manzil', 'Address');
  String get phone => _t('Телефон', 'Telefon', 'Phone');
  String get allStatuses => _t('Все статусы', 'Barcha holatlar', 'All statuses');
  String get copyLink => _t('Скопировать', 'Nusxalash', 'Copy');
  String get copied => _t('Скопировано', 'Nusxalandi', 'Copied');
  String get comment => _t('Комментарий', 'Izoh', 'Comment');
  String get openLink => _t('Открыть', 'Ochish', 'Open');
  String get orderCommentLbl => _t('Комментарий к заказу', 'Buyurtmaga izoh', 'Order comment');
  String get orderCommentHint => _t('Опишите заказ...', 'Buyurtmani tasvirlab bering...', 'Describe the order...');
  String get orderAmountLbl => _t('Сумма заказа', 'Buyurtma summasi', 'Order Amount');
  String get customerCommentLbl => _t('Комментарий клиента', 'Mijoz izohi', 'Customer comment');
  String get shareOrderLink => _t('Ссылка для клиента', 'Mijoz havolasi', 'Customer link');
  String get totalAmountLbl => _t('Итого', 'Jami', 'Total');

  // Status labels
  String get stPending => _t('Ожидает клиента', 'Mijoz kutilmoqda', 'Awaiting customer');
  String get stAwaiting =>
      _t('Ожид. подтверждения', 'Tasdiqlash kutmoqda', 'Awaiting confirmation');
  String get stConfirmed => _t('Подтверждён', 'Tasdiqlandi', 'Confirmed');
  String get stPickup => _t('Курьер едет', 'Kuryer kelmoqda', 'Courier en route');
  String get stPicked => _t('Курьер забрал', 'Kuryer oldi', 'Picked up');
  String get stDelivery => _t('Доставка', 'Yetkazilmoqda', 'In delivery');
  String get stDelivered => _t('Доставлен', 'Yetkazildi', 'Delivered');
  String get stCancelled => _t('Отменён', 'Bekor qilindi', 'Cancelled');

  // Clients
  String get noClients => _t("Нет клиентов", "Mijozlar yo'q", 'No clients');
  String get clientsSubtitle =>
      _t('Клиенты появятся после первых заказов', 'Mijozlar birinchi buyurtmalardan keyin paydo bo\'ladi', 'Clients will appear after first orders');
  String get clientDetails =>
      _t("Информация о клиенте", "Mijoz haqida ma'lumot", 'Client Details');
  String get ordersCount => _t('заказов', 'buyurtma', 'orders');
  String get lastOrder => _t('Последний заказ', 'Oxirgi buyurtma', 'Last order');
  String get minOrders => _t('Мин. заказов', 'Min. buyurtmalar', 'Min orders');
  String get searchByPhone =>
      _t('Поиск по телефону или имени', "Telefon yoki ism bo'yicha", 'Search by phone or name');

  // Analytics
  String get totalOrdersLbl =>
      _t('Всего заказов', 'Jami buyurtmalar', 'Total Orders');
  String get medicinesAmountLbl =>
      _t('Сумма продаж', 'Savdo summasi', 'Sales Amount');
  String get deliveryRevenueLbl =>
      _t('Выручка доставки', 'Yetkazib berish daromadi', 'Delivery Revenue');
  String get totalRevenueLbl =>
      _t('Общая выручка', 'Umumiy daromad', 'Total Revenue');
  String get ordersByDayLbl =>
      _t('Заказы по дням', 'Kunlik buyurtmalar', 'Orders by Day');
  String get ordersByStatusLbl =>
      _t("По статусам", "Holat bo'yicha", 'By Status');
  String get ordersByCourierLbl =>
      _t("По курьерам", "Kuryer bo'yicha", 'By Courier');

  // Settings
  String get profileStore => _t("Профиль магазина", "Do'kon profili", 'Store Profile');
  String get changePassword =>
      _t('Изменить пароль', "Parolni o'zgartirish", 'Change Password');
  String get subscription => _t('Подписка', 'Obuna', 'Subscription');
  String get aboutApp => _t('О приложении', 'Ilova haqida', 'About App');
  String get termsOfService => _t('Условия использования', 'Foydalanish shartlari', 'Terms of Service');
  String get privacyPolicy => _t('Политика конфиденциальности', 'Maxfiylik siyosati', 'Privacy Policy');
  String get appearance => _t('Внешний вид', "Ko'rinish", 'Appearance');
  String get account => _t('Аккаунт', 'Akkaunt', 'Account');
  String get application => _t('Приложение', 'Ilova', 'Application');
  String get language => _t('Язык', 'Til', 'Language');
  String get hapticFeedback => _t('Виброотклик', 'Tebranish', 'Haptic Feedback');
  String get theme => _t('Тема', 'Mavzu', 'Theme');
  String get themeDark => _t('Тёмная', "Qorong'u", 'Dark');
  String get themeLight => _t("Светлая", "Yorug'", 'Light');
  String get themeSystem => _t('Системная', 'Tizim', 'System');
  String get location => _t('Местоположение', 'Joylashuv', 'Location');
  String get updateLocation =>
      _t('Обновить местоположение', 'Joylashuvni yangilash', 'Update Location');
  String get paySubscription =>
      _t('Продлить подписку', 'Obunani uzaytirish', 'Renew Subscription');
  String get subscriptionActive => _t('Активна', 'Faol', 'Active');
  String get subscriptionExpired => _t('Истекла', 'Tugagan', 'Expired');
  String get daysLeft => _t('дн. осталось', 'kun qoldi', 'days left');
  String get payments => _t('Платежи', "To'lovlar", 'Payments');
  String get noPaymentsYet => _t('Платежей пока нет', "Hozircha to'lovlar yo'q", 'No payments yet');
  String get subscriptionValidUntil => _t('Действует до', 'Amal qilish muddati', 'Valid until');
  String get subscriptionExpiringSoon => _t('Скоро истекает', 'Tez orada tugaydi', 'Expiring soon');
  String get logoutConfirm =>
      _t('Выйти из аккаунта?', 'Hisobdan chiqasizmi?', 'Log out?');
  String get storeNameLbl => _t("Название магазина", "Do'kon nomi", 'Store Name');
  String get emailLbl => _t('Email', 'Email', 'Email');
  String get phoneLbl => _t('Телефон', 'Telefon', 'Phone');
  String get passwordLbl => _t('Пароль', 'Parol', 'Password');
  String get loginFieldLbl => _t('Логин', 'Login', 'Login');
  String get enterLoginHint => _t('Введите логин', 'Loginni kiriting', 'Enter login');
  String get enterPasswordHint => _t('Введите пароль', 'Parolni kiriting', 'Enter password');
  String get oldPasswordLbl => _t('Старый пароль', 'Eski parol', 'Old Password');
  String get newPasswordLbl => _t('Новый пароль', 'Yangi parol', 'New Password');
  String get confirmPasswordLbl =>
      _t('Подтвердите новый пароль', 'Yangi parolni tasdiqlang', 'Confirm Password');
  String get changePasswordTitle =>
      _t('Изменить пароль', "Parolni o'zgartirish", 'Change Password');
  String get passwordChanged =>
      _t('Пароль успешно изменён', 'Parol muvaffaqiyatli o\'zgardi', 'Password changed');
  String get passwordsNoMatch =>
      _t('Новые пароли не совпадают', 'Yangi parollar mos emas', 'Passwords do not match');
  String get passwordTooShort =>
      _t('Пароль должен содержать минимум 6 символов', 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak', 'Password must be at least 6 characters');
  String get fillAllFields =>
      _t('Заполните все поля', "Barcha maydonlarni to'ldiring", 'Fill all fields');
  String get nameCantBeEmpty =>
      _t('Название не может быть пустым', "Nom bo'sh bo'lishi mumkin emas", 'Name cannot be empty');
  String get saveError => _t("Не удалось сохранить", "Saqlab bo'lmadi", 'Could not save');
  String get changPasswordError =>
      _t('Не удалось изменить пароль', "Parolni o'zgartirib bo'lmadi", 'Could not change password');

  // Location
  String get locationTitle =>
      _t('Выбор местоположения', 'Joylashuvni tanlash', 'Pick Location');
  String get searchAddress => _t('Поиск адреса...', 'Manzil qidirish...', 'Search address...');
  String get determiningAddress =>
      _t('Определяю адрес...', 'Manzil aniqlanmoqda...', 'Determining address...');
  String get unknownAddress =>
      _t('Адрес не определён', 'Manzil aniqlanmadi', 'Address unknown');
  String get confirmLocation =>
      _t('Подтвердить местоположение', 'Joylashuvni tasdiqlash', 'Confirm Location');
  String get locationSaved =>
      _t('Местоположение обновлено', 'Joylashuv yangilandi', 'Location updated');
  String get locationError => _t('Ошибка сохранения', 'Saqlashda xatolik', 'Save error');

  // Errors
  String get errorLoading => _t('Ошибка загрузки', 'Yuklashda xatolik', 'Loading error');

  // Admin — navigation
  String get businesses => _t('Магазины', 'Do\'konlar', 'Businesses');
  String get activations => _t('Активации', 'Aktivatsiyalar', 'Activations');
  String get adminSettings => _t('Настройки', 'Sozlamalar', 'Settings');
  String get adminProfile => _t('Профиль', 'Profil', 'Profile');
  String get roles => _t('Роли', 'Rollar', 'Roles');

  // Admin — orders screen
  String get adminOrdersTitle => _t('Заказы', 'Buyurtmalar', 'Orders');
  String get adminOrderSum => _t('Сумма', 'Summa', 'Amount');
  String get adminOrderDate => _t('Дата', 'Sana', 'Date');
  String get adminOrderCourier => _t('Курьер', 'Kuryer', 'Courier');
  String get adminOrderPharmacy => _t('Магазин', 'Do\'kon', 'Business');
  String get adminConfirmOrder => _t('Подтвердить', 'Tasdiqlash', 'Confirm');
  String get adminDeleteOrder => _t('Удалить заказ?', 'Buyurtmani o\'chirish?', 'Delete order?');
  String get adminDeleteOrderMsg => _t('Это действие нельзя отменить.', 'Bu amalni qaytarib bo\'lmaydi.', 'This cannot be undone.');
  String get adminOrderConfirmed => _t('Заказ подтверждён', 'Buyurtma tasdiqlandi', 'Order confirmed');
  String get adminOrderDeleted => _t('Заказ удалён', 'Buyurtma o\'chirildi', 'Order deleted');
  String get adminOrderError => _t('Ошибка', 'Xatolik', 'Error');
  String get adminNoOrders => _t('Нет заказов', 'Buyurtmalar yo\'q', 'No orders');
  String get adminNoOrdersSub => _t('Заказы появятся после создания', 'Buyurtmalar yaratilgandan keyin paydo bo\'ladi', 'Orders will appear after creation');
  String get adminSearchOrders => _t('Поиск по токену, клиенту...', 'Token, mijoz bo\'yicha...', 'Search by token, client...');
  String get adminFilterCourier => _t('Курьер', 'Kuryer', 'Courier');
  String get adminFilterDate => _t('Дата', 'Sana', 'Date');
  String get adminCourierAll => _t('Все курьеры', 'Barcha kuryerlar', 'All couriers');
  String get adminStatusAll => _t('Все', 'Hammasi', 'All');

  // Admin — clients screen
  String get adminClientsTitle => _t('Клиенты', 'Mijozlar', 'Clients');
  String get adminSearchClients => _t('Поиск по телефону или имени...', 'Telefon yoki ism...', 'Search by phone or name...');
  String get adminClientsOrders => _t('заказов', 'buyurtma', 'orders');
  String get adminNoClients => _t('Нет клиентов', 'Mijozlar yo\'q', 'No clients');
  String get adminMinOrders => _t('Мин. заказов', 'Min. buyurtma', 'Min orders');

  // Admin — businesses screen
  String get adminBusinessesTitle => _t('Магазины', 'Do\'konlar', 'Businesses');
  String get adminSearchBusiness => _t('Поиск магазина...', 'Do\'kon qidirish...', 'Search business...');
  String get adminBusinessActive => _t('Активна', 'Faol', 'Active');
  String get adminBusinessInactive => _t('Неактивна', 'Faol emas', 'Inactive');
  String get adminBusinessOrders => _t('заказов', 'buyurtma', 'orders');
  String get adminSubExpired => _t('Подписка истекла', 'Obuna tugadi', 'Subscription expired');
  String get adminSubDays => _t('Подписка:', 'Obuna:', 'Subscription:');
  String get adminSubDaysSuffix => _t('дн.', 'kun', 'days');
  String get adminNoBusinesses => _t('Нет магазинов', 'Do\'konlar yo\'q', 'No businesses');
  String get adminNoBusinessesSub => _t('Магазины появятся после регистрации', 'Do\'konlar ro\'yxatdan o\'tgandan keyin paydo bo\'ladi', 'Businesses will appear after registration');

  // Admin — analytics screen
  String get adminAnalyticsTitle => _t('Аналитика', 'Analitika', 'Analytics');
  String get adminTotalOrders => _t('Всего заказов', 'Jami buyurtmalar', 'Total Orders');
  String get adminActivePharmacies => _t('Активных магазинов', 'Faol do\'konlar', 'Active Businesses');
  String get adminMedicinesAmount => _t('Сумма лекарств', 'Dorilar summasi', 'Medicines Amount');
  String get adminDeliveryAmount => _t('Выручка доставки', 'Yetkazib berish', 'Delivery Revenue');
  String get adminTotalRevenue => _t('Общая выручка', 'Umumiy daromad', 'Total Revenue');
  String get adminOrdersByDay => _t('Заказы по дням (30 дней)', 'Kunlik buyurtmalar (30 kun)', 'Orders by Day (30 days)');
  String get adminByStatus => _t('По статусам', 'Holat bo\'yicha', 'By Status');
  String get adminByCourier => _t('По курьерам', 'Kuryer bo\'yicha', 'By Courier');

  // Admin — activations screen
  String get adminActivationsTitle => _t('Активации', 'Aktivatsiyalar', 'Activations');
  String get adminActivationSearch => _t('Поиск по магазину...', "Do'kon bo'yicha...", 'Search by store...');
  String get adminActivationSelfRegistered => _t('Самостоятельно', "O'zi ro'yxatdan o'tgan", 'Self-registered');
  String get adminActivationSuperAdmin => _t('Суперадмин', 'Superadmin', 'Superadmin');
  String get adminActivationByUser => _t('Пользователь', 'Foydalanuvchi', 'User');
  String get adminActivationWhoAdded => _t('Кто добавил', "Kim qo'shdi", 'Who added');
  String get adminActivationCreator => _t('Добавил', "Qo'shdi", 'Added by');
  String get adminActivationReassign => _t('Переназначить', "Qayta tayinlash", 'Reassign');
  String get adminActivationReassigned => _t('Переназначено', "Qayta tayinlandi", 'Reassigned');
  String get adminActivationTotal => _t('Всего', 'Jami', 'Total');
  String get adminActivationStatusFilter => _t('Статус магазина', "Do'kon holati", 'Store status');
  String get adminActivationDateAdded => _t('Дата добавления', "Qo'shilgan sana", 'Date added');
  String get adminActivationAnalytics => _t('Аналитика', 'Analitika', 'Analytics');
  String get adminActivationList => _t('Список', "Ro'yxat", 'List');

  // Language
  String get langUz => "O'zbek";
  String get langRu => _t('Русский', 'Rus tili', 'Russian');
  String get langEn => _t('English', 'Ingliz tili', 'English');
  String get changeLanguage => _t('Язык', 'Til', 'Language');

  // Admin orders — additional
  String get adminCancelOrder => _t('Отменить заказ', 'Buyurtmani bekor qilish', 'Cancel Order');
  String get adminOrderCancelled => _t('Заказ отменён', 'Buyurtma bekor qilindi', 'Order cancelled');
  String get adminCreateOrder => _t('Создать заказ', 'Buyurtma yaratish', 'Create Order');
  String get adminCreateOrderTitle => _t("Новый заказ (от магазина)", "Yangi buyurtma (do'kon nomidan)", 'New Order (from store)');
  String get adminSelectPharmacy => _t("Выберите магазин", "Do'kon tanlang", 'Select store');
  String get adminOrderCreated => _t('Заказ создан', 'Buyurtma yaratildi', 'Order created');
  String get adminOrderDetailTitle => _t('Детали заказа', 'Buyurtma tafsilotlari', 'Order Details');
  String get adminPharmacyLbl => _t('Магазин', "Do'kon", 'Store');

  // Admin businesses — additional
  String get adminCreateBusiness => _t("Создать магазин", "Do'kon yaratish", 'Create Business');
  String get adminEditBusiness => _t('Редактировать', 'Tahrirlash', 'Edit');
  String get adminDeleteBusiness => _t("Удалить магазин?", "Do'konni o'chirish?", 'Delete business?');
  String get adminDeleteBusinessMsg => _t("Это действие нельзя отменить.", "Bu amal qaytarib bo'lmaydi.", 'This cannot be undone.');
  String get adminBusinessCreated => _t("Магазин создан", "Do'kon yaratildi", 'Business created');
  String get adminBusinessUpdated => _t("Магазин обновлён", "Do'kon yangilandi", 'Business updated');
  String get adminBusinessDeleted => _t("Магазин удалён", "Do'kon o'chirildi", 'Business deleted');
  String get adminBusinessOwner => _t('Владелец', 'Egasi', 'Owner');
  String get adminBusinessPhoneLbl => _t('Телефон', 'Telefon', 'Phone');
  String get adminBusinessLoginLbl => _t('Логин', 'Login', 'Login');
  String get adminBusinessPasswordLbl => _t('Пароль', 'Parol', 'Password');
  String get adminBusinessAddressLbl => _t('Адрес', 'Manzil', 'Address');
  String get adminBusinessSubExpiry => _t('Дата окончания подписки', 'Obuna tugash sanasi', 'Subscription expiry');
  String get adminBusinessCouriers => _t("Разрешённые курьеры", "Ruxsat etilgan kuryerlar", 'Allowed couriers');
  String get adminBusinessStatusFilter => _t('Статус', 'Holat', 'Status');
  String get adminBusinessDetail => _t('Информация о магазине', "Do'kon haqida ma'lumot", 'Store details');

  // Admin clients — additional
  String get adminClientAddresses => _t('Адреса', 'Manzillar', 'Addresses');
  String get adminClientCompanies => _t("Магазины", "Do'konlar", 'Stores');
  String get adminClientLastOrder => _t('Последний заказ', 'Oxirgi buyurtma', 'Last order');

  // Permission sections
  String get permSectionOrders => _t('Заказы', 'Buyurtmalar', 'Orders');
  String get permSectionPharmacies => _t("Магазины", "Do'konlar", 'Businesses');
  String get permSectionClients => _t('Клиенты', 'Mijozlar', 'Clients');
  String get permSectionAnalytics => _t('Аналитика', 'Analitika', 'Analytics');
  String get permSectionActivations => _t('Активации', 'Aktivatsiyalar', 'Activations');

  // Admin — roles screen
  String get adminRolesTitle => _t('Управление ролями', 'Rollarni boshqarish', 'Role Management');
  String get adminRolesTab => _t('Роли', 'Rollar', 'Roles');
  String get adminUsersTab => _t('Пользователи', 'Foydalanuvchilar', 'Users');
  String get adminCreateRole => _t('Создать роль', 'Rol yaratish', 'Create Role');
  String get adminEditRole => _t('Редактировать роль', 'Rolni tahrirlash', 'Edit Role');
  String get adminDeleteRole => _t('Удалить роль?', 'Rolni o\'chirish?', 'Delete role?');
  String get adminNoRoles => _t('Нет ролей', 'Rollar yo\'q', 'No roles');
  String get adminNoRolesSub => _t('Создайте первую роль', 'Birinchi rolni yarating', 'Create your first role');
  String get adminRoleName => _t('Название роли', 'Rol nomi', 'Role name');
  String get adminRoleNameHint => _t('Например: Менеджер заказов', 'Masalan: Buyurtma menejeri', 'E.g.: Orders Manager');
  String get adminPermissions => _t('Права доступа', 'Huquqlar', 'Permissions');
  String get adminSelectAll => _t('Выбрать все', 'Barchasini tanlash', 'Select all');
  String get adminClearAll => _t('Сбросить', 'Tozalash', 'Clear all');
  String get adminSaveRole => _t('Сохранить роль', 'Rolni saqlash', 'Save Role');
  String get adminRoleCreated => _t('Роль создана', 'Rol yaratildi', 'Role created');
  String get adminRoleUpdated => _t('Роль обновлена', 'Rol yangilandi', 'Role updated');
  String get adminRoleDeleted => _t('Роль удалена', 'Rol o\'chirildi', 'Role deleted');
  String get adminRoleExists => _t('Роль с таким именем уже существует', 'Bu nomli rol mavjud', 'Role name already exists');
  String get adminCreateUser => _t('Создать пользователя', 'Foydalanuvchi yaratish', 'Create User');
  String get adminEditUser => _t('Редактировать', 'Tahrirlash', 'Edit');
  String get adminDeleteUser => _t('Удалить пользователя?', 'Foydalanuvchini o\'chirish?', 'Delete user?');
  String get adminNoUsers => _t('Нет пользователей', 'Foydalanuvchilar yo\'q', 'No users');
  String get adminUserEmail => _t('Email', 'Email', 'Email');
  String get adminUserRoles => _t('Роли', 'Rollar', 'Roles');
  String get adminUserActive => _t('Активен', 'Faol', 'Active');
  String get adminUserInactive => _t('Неактивен', 'Faol emas', 'Inactive');
  String get adminUserCreated => _t('Пользователь создан', 'Foydalanuvchi yaratildi', 'User created');
  String get adminUserUpdated => _t('Пользователь обновлён', 'Foydalanuvchi yangilandi', 'User updated');
  String get adminUserDeleted => _t('Пользователь удалён', 'Foydalanuvchi o\'chirildi', 'User deleted');
  String get adminPasswordLeaveBlank => _t('оставьте пустым, чтобы не менять', 'o\'zgartirmaslik uchun bo\'sh qoldiring', 'leave blank to keep');
  String get adminPasswordMin => _t('Минимум 6 символов', 'Kamida 6 belgi', 'At least 6 characters');
  String get adminEmailInUse => _t('Email уже используется', 'Email allaqachon ishlatilmoqda', 'Email already in use');
  String get adminActiveAccount => _t('Активный аккаунт', 'Faol akkaunt', 'Active account');
  String get adminNoAvailableRoles => _t('Нет доступных ролей', 'Rollar mavjud emas', 'No roles available');
  String get adminSelectedPermissions => _t('Выбрано прав', 'Tanlangan huquqlar', 'Permissions selected');

  // Admin — settings/profile screen
  String get adminProfileTitle => _t('Профиль', 'Profil', 'Profile');
  String get adminSettingsTitle => _t('Настройки', 'Sozlamalar', 'Settings');
  String get adminProfileInfo => _t('Информация', 'Ma\'lumot', 'Information');
  String get adminProfileName => _t('Имя', 'Ism', 'Name');
  String get adminProfileEmail => _t('Email', 'Email', 'Email');
  String get adminProfileRole => _t('Тип', 'Tur', 'Type');
  String get adminSuperAdmin => _t('Супер администратор', 'Super administrator', 'Super Admin');
  String get adminRegularUser => _t('Пользователь', 'Foydalanuvchi', 'User');
  String get adminProfilePermissionsSection => _t('Мои права доступа', 'Mening huquqlarim', 'My Permissions');
  String get adminRoleManagementSection => _t('Управление ролями и пользователями', 'Rollar va foydalanuvchilarni boshqarish', 'Role & User Management');
  String get adminGoToRoles => _t('Роли и пользователи', 'Rollar va foydalanuvchilar', 'Roles & Users');
  String get adminAppearanceSection => _t('Внешний вид', 'Ko\'rinish', 'Appearance');
  String get adminLogoutConfirm => _t('Выйти из аккаунта?', 'Hisobdan chiqasizmi?', 'Log out?');

  // Permissions labels
  String get permOrdersView => _t('Просмотр заказов', 'Buyurtmalarni ko\'rish', 'View orders');
  String get permOrdersCreate => _t('Создание заказов', 'Buyurtma yaratish', 'Create orders');
  String get permOrdersConfirm => _t('Подтверждение заказов', 'Buyurtmani tasdiqlash', 'Confirm orders');
  String get permOrdersCancel => _t('Отмена заказов', 'Buyurtmani bekor qilish', 'Cancel orders');
  String get permOrdersDelete => _t('Удаление заказов', 'Buyurtmani o\'chirish', 'Delete orders');
  String get permPharmaciesView => _t('Просмотр магазинов', 'Do\'konlarni ko\'rish', 'View businesses');
  String get permPharmaciesCreate => _t('Создание магазинов', 'Do\'kon yaratish', 'Create businesses');
  String get permPharmaciesEdit => _t('Редактирование магазинов', 'Do\'konni tahrirlash', 'Edit businesses');
  String get permPharmaciesDelete => _t('Удаление магазинов', 'Do\'konni o\'chirish', 'Delete businesses');
  String get permClientsView => _t('Просмотр клиентов', 'Mijozlarni ko\'rish', 'View clients');
  String get permAnalyticsView => _t('Просмотр аналитики', 'Analitikani ko\'rish', 'View analytics');
  String get permActivationsView => _t('Просмотр активаций', 'Aktivatsiyalarni ko\'rish', 'View activations');

  // ─── Date formatting ──────────────────────────────────────────────────────

  String _monthFull(int m) => switch (m) {
        1  => _t('января',   'yanvar',  'January'),
        2  => _t('февраля',  'fevral',  'February'),
        3  => _t('марта',    'mart',    'March'),
        4  => _t('апреля',   'aprel',   'April'),
        5  => _t('мая',      'may',     'May'),
        6  => _t('июня',     'iyun',    'June'),
        7  => _t('июля',     'iyul',    'July'),
        8  => _t('августа',  'avgust',  'August'),
        9  => _t('сентября', 'sentabr', 'September'),
        10 => _t('октября',  'oktabr',  'October'),
        11 => _t('ноября',   'noyabr',  'November'),
        _  => _t('декабря',  'dekabr',  'December'),
      };

  String _monthShort(int m) => switch (m) {
        1  => _t('янв', 'yan', 'Jan'),
        2  => _t('фев', 'fev', 'Feb'),
        3  => _t('мар', 'mar', 'Mar'),
        4  => _t('апр', 'apr', 'Apr'),
        5  => _t('мая', 'may', 'May'),
        6  => _t('июн', 'iyn', 'Jun'),
        7  => _t('июл', 'iyl', 'Jul'),
        8  => _t('авг', 'avg', 'Aug'),
        9  => _t('сен', 'sen', 'Sep'),
        10 => _t('окт', 'okt', 'Oct'),
        11 => _t('ноя', 'noy', 'Nov'),
        _  => _t('дек', 'dek', 'Dec'),
      };

  /// "13 мая 2026  13:05"
  String fmtDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${_monthFull(dt.month)} ${dt.year}  $h:$min';
    } catch (_) {
      return iso;
    }
  }

  /// "13 мая  13:05" (без года, для карточек)
  String fmtDateTimeShort(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${_monthShort(dt.month)}  $h:$min';
    } catch (_) {
      return iso;
    }
  }

  /// "13 мая 2026" (только дата, из ISO-строки)
  String fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day} ${_monthFull(dt.month)} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  /// "13 мая 2026" (только дата, из DateTime)
  String fmtDateDt(DateTime dt) =>
      '${dt.day} ${_monthFull(dt.month)} ${dt.year}';

  /// "13 мая" (день + краткий месяц, для чипов фильтра)
  String fmtDateShort(DateTime dt) =>
      '${dt.day} ${_monthShort(dt.month)}';

  String permissionLabel(String perm) => switch (perm) {
    'orders:view'       => permOrdersView,
    'orders:create'     => permOrdersCreate,
    'orders:confirm'    => permOrdersConfirm,
    'orders:cancel'     => permOrdersCancel,
    'orders:delete'     => permOrdersDelete,
    'pharmacies:view'   => permPharmaciesView,
    'pharmacies:create' => permPharmaciesCreate,
    'pharmacies:edit'   => permPharmaciesEdit,
    'pharmacies:delete' => permPharmaciesDelete,
    'clients:view'      => permClientsView,
    'analytics:view'    => permAnalyticsView,
    'activations:view'  => permActivationsView,
    _                   => perm,
  };
}

extension AppL10nContext on BuildContext {
  AppL10n get l10n =>
      AppL10n.fromCode(Localizations.localeOf(this).languageCode);
}
