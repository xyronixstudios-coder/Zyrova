import 'package:flutter/material.dart';

class AppStrings {
  final String appName;
  final String tagline;
  final String home;
  final String discover;
  final String popular;
  final String upload;
  final String messages;
  final String profile;
  final String settings;
  final String search;
  final String follow;
  final String following;
  final String follows;
  final String posts;
  final String followers;
  final String likes;
  final String comments;
  final String share;
  final String save;
  final String cancel;
  final String delete;
  final String edit;
  final String logout;
  final String login;
  final String register;
  final String email;
  final String password;
  final String username;
  final String bio;
  final String noVideos;
  final String uploadFirst;
  final String followFirst;
  final String loading;
  final String error;
  final String success;
  final String account;
  final String privacy;
  final String notifications;
  final String storageCache;
  final String appearance;
  final String language;
  final String help;
  final String about;
  final String theme;
  final String dark;
  final String light;
  final String accentColor;
  final String bannerColor;
  final String bannerType;
  final String solid;
  final String gradient;
  final String pattern;
  final String dots;
  final String stripes;
  final String waves;
  final String circles;
  final String none;
  final String editProfile;
  final String changePassword;
  final String deleteAccount;
  final String producer;
  final String studio;
  final String developer;
  final String version;
  final String license;
  final String technology;
  final String allRightsReserved;
  final String faq;
  final String contact;
  final String videoUploaded;
  final String videoDeleted;
  final String profileSaved;
  final String passwordChanged;
  final String confirmLogout;
  final String confirmDelete;
  final String selectVideo;
  final String camera;
  final String gallery;
  final String title;
  final String caption;
  final String uploadBtn;
  final String videoMax;
  final String secondColor;
  final String primaryColor;
  final String colorLabel;
  final String videoTooBig;
  final String noCommentsYet;
  final String firstComment;
  final String writeComment;
  final String deleteCommentTitle;
  final String deleteCommentConfirm;
  final String deleteVideoTitle;
  final String deleteVideoConfirm;
  final String deleteAccountConfirm;
  final String changePasswordHint;
  final String hintAboutYou;
  final String aboutApp;
  final String webSite;
  final String gmail;
  final String pickEmailApp;

  const AppStrings({
    required this.appName,
    required this.tagline,
    required this.home,
    required this.discover,
    required this.popular,
    required this.upload,
    required this.messages,
    required this.profile,
    required this.settings,
    required this.search,
    required this.follow,
    required this.following,
    required this.follows,
    required this.posts,
    required this.followers,
    required this.likes,
    required this.comments,
    required this.share,
    required this.save,
    required this.cancel,
    required this.delete,
    required this.edit,
    required this.logout,
    required this.login,
    required this.register,
    required this.email,
    required this.password,
    required this.username,
    required this.bio,
    required this.noVideos,
    required this.uploadFirst,
    required this.followFirst,
    required this.loading,
    required this.error,
    required this.success,
    required this.account,
    required this.privacy,
    required this.notifications,
    required this.storageCache,
    required this.appearance,
    required this.language,
    required this.help,
    required this.about,
    required this.theme,
    required this.dark,
    required this.light,
    required this.accentColor,
    required this.bannerColor,
    required this.bannerType,
    required this.solid,
    required this.gradient,
    required this.pattern,
    required this.dots,
    required this.stripes,
    required this.waves,
    required this.circles,
    required this.none,
    required this.editProfile,
    required this.changePassword,
    required this.deleteAccount,
    required this.producer,
    required this.studio,
    required this.developer,
    required this.version,
    required this.license,
    required this.technology,
    required this.allRightsReserved,
    required this.faq,
    required this.contact,
    required this.videoUploaded,
    required this.videoDeleted,
    required this.profileSaved,
    required this.passwordChanged,
    required this.confirmLogout,
    required this.confirmDelete,
    required this.selectVideo,
    required this.camera,
    required this.gallery,
    required this.title,
    required this.caption,
    required this.uploadBtn,
    required this.videoMax,
    required this.secondColor,
    required this.primaryColor,
    required this.colorLabel,
    required this.videoTooBig,
    required this.noCommentsYet,
    required this.firstComment,
    required this.writeComment,
    required this.deleteCommentTitle,
    required this.deleteCommentConfirm,
    required this.deleteVideoTitle,
    required this.deleteVideoConfirm,
    required this.deleteAccountConfirm,
    required this.changePasswordHint,
    required this.hintAboutYou,
    required this.aboutApp,
    required this.webSite,
    required this.gmail,
    required this.pickEmailApp,
  });
}

class AppL {
  static AppStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'en' ? _en : _tr;
  }

  static const _tr = AppStrings(
    appName: 'Zyrova',
    tagline: 'Akıcı bir akış. Akıllı cache.',
    home: 'Ana Sayfa',
    discover: 'Keşfet',
    popular: 'Popüler',
    upload: 'Yükle',
    messages: 'Mesajlar',
    profile: 'Profil',
    settings: 'Ayarlar',
    search: 'Ara',
    follow: 'Takip Et',
    following: 'Takip',
    follows: 'Takip',
    posts: 'Gönderi',
    followers: 'Takipçi',
    likes: 'Beğeni',
    comments: 'Yorum',
    share: 'Paylaş',
    save: 'Kaydet',
    cancel: 'İptal',
    delete: 'Sil',
    edit: 'Düzenle',
    logout: 'Çıkış Yap',
    login: 'Giriş Yap',
    register: 'Kayıt Ol',
    email: 'E-posta',
    password: 'Şifre',
    username: 'Kullanıcı Adı',
    bio: 'Hakkında',
    noVideos: 'Henüz video yok',
    uploadFirst: 'Yükle sekmesinden ilk videonu paylaş!',
    followFirst: 'Takip ettiğin kişilerin videoları burada',
    loading: 'Yükleniyor...',
    error: 'Hata',
    success: 'Başarılı',
    account: 'Hesap',
    privacy: 'Gizlilik',
    notifications: 'Bildirimler',
    storageCache: 'Depolama ve Cache',
    appearance: 'Görünüm',
    language: 'Dil',
    help: 'Yardım & Destek',
    about: 'Hakkında',
    theme: 'Tema',
    dark: 'Koyu',
    light: 'Açık',
    accentColor: 'Vurgu Rengi',
    bannerColor: 'Banner Rengi',
    bannerType: 'Banner Tipi',
    solid: 'Düz',
    gradient: 'Gradient',
    pattern: 'Desen',
    dots: 'Noktalar',
    stripes: 'Çizgiler',
    waves: 'Dalgalar',
    circles: 'Daireler',
    none: 'Yok',
    editProfile: 'Profili Düzenle',
    changePassword: 'Şifre Değiştir',
    deleteAccount: 'Hesabı Sil',
    producer: 'Yapımcı',
    studio: 'Stüdyo',
    developer: 'Geliştirici',
    version: 'Versiyon',
    license: 'Lisans',
    technology: 'Teknoloji',
    allRightsReserved: 'Tüm hakları saklıdır.',
    faq: 'Sıkça Sorulan Sorular',
    contact: 'İletişim',
    videoUploaded: 'Video yüklendi!',
    videoDeleted: 'Video silindi',
    profileSaved: 'Profil kaydedildi',
    passwordChanged: 'Şifre güncellendi',
    confirmLogout: 'Çıkış yapmak istediğine emin misin?',
    confirmDelete: 'Silmek istediğine emin misin?',
    selectVideo: 'Video Seç',
    camera: 'Kamera',
    gallery: 'Galeri',
    title: 'Başlık',
    caption: 'Açıklama',
    uploadBtn: 'Yükle',
    videoMax: 'Video max 50 MB olmalı',
    secondColor: 'İkinci Renk',
    primaryColor: 'Ana Renk',
    colorLabel: 'Renk',
    videoTooBig: 'Video çok büyük',
    noCommentsYet: 'Henüz yorum yok',
    firstComment: 'İlk yorumu sen yap!',
    writeComment: 'Yorum yaz...',
    deleteCommentTitle: 'Yorumu Sil',
    deleteCommentConfirm: 'Bu yorumu silmek istediğine emin misin?',
    deleteVideoTitle: 'Videoyu Sil',
    deleteVideoConfirm: 'silmek istediğine emin misin?',
    deleteAccountConfirm: 'Hesabın ve tüm videoların silinecek. Emin misin?',
    changePasswordHint: 'Yeni şifre (min 6)',
    hintAboutYou: 'Kendinden bahset...',
    aboutApp: 'Uygulama',
    webSite: 'Web Sitesi',
    gmail: 'E-posta',
    pickEmailApp: 'E-posta uygulaması açılamadı',
  );

  static const _en = AppStrings(
    appName: 'Zyrova',
    tagline: 'Smooth flow. Smart cache.',
    home: 'Home',
    discover: 'Discover',
    popular: 'Popular',
    upload: 'Upload',
    messages: 'Messages',
    profile: 'Profile',
    settings: 'Settings',
    search: 'Search',
    follow: 'Follow',
    following: 'Following',
    follows: 'Following',
    posts: 'Posts',
    followers: 'Followers',
    likes: 'Likes',
    comments: 'Comments',
    share: 'Share',
    save: 'Save',
    cancel: 'Cancel',
    delete: 'Delete',
    edit: 'Edit',
    logout: 'Logout',
    login: 'Login',
    register: 'Register',
    email: 'Email',
    password: 'Password',
    username: 'Username',
    bio: 'Bio',
    noVideos: 'No videos yet',
    uploadFirst: 'Upload your first video!',
    followFirst: 'Videos from people you follow will appear here',
    loading: 'Loading...',
    error: 'Error',
    success: 'Success',
    account: 'Account',
    privacy: 'Privacy',
    notifications: 'Notifications',
    storageCache: 'Storage & Cache',
    appearance: 'Appearance',
    language: 'Language',
    help: 'Help & Support',
    about: 'About',
    theme: 'Theme',
    dark: 'Dark',
    light: 'Light',
    accentColor: 'Accent Color',
    bannerColor: 'Banner Color',
    bannerType: 'Banner Type',
    solid: 'Solid',
    gradient: 'Gradient',
    pattern: 'Pattern',
    dots: 'Dots',
    stripes: 'Stripes',
    waves: 'Waves',
    circles: 'Circles',
    none: 'None',
    editProfile: 'Edit Profile',
    changePassword: 'Change Password',
    deleteAccount: 'Delete Account',
    producer: 'Producer',
    studio: 'Studio',
    developer: 'Developer',
    version: 'Version',
    license: 'License',
    technology: 'Technology',
    allRightsReserved: 'All rights reserved.',
    faq: 'Frequently Asked Questions',
    contact: 'Contact',
    videoUploaded: 'Video uploaded!',
    videoDeleted: 'Video deleted',
    profileSaved: 'Profile saved',
    passwordChanged: 'Password updated',
    confirmLogout: 'Are you sure you want to logout?',
    confirmDelete: 'Are you sure you want to delete?',
    selectVideo: 'Select Video',
    camera: 'Camera',
    gallery: 'Gallery',
    title: 'Title',
    caption: 'Caption',
    uploadBtn: 'Upload',
    videoMax: 'Video must be max 50 MB',
    secondColor: 'Second Color',
    primaryColor: 'Primary Color',
    colorLabel: 'Color',
    videoTooBig: 'Video too big',
    noCommentsYet: 'No comments yet',
    firstComment: 'Be the first to comment!',
    writeComment: 'Write a comment...',
    deleteCommentTitle: 'Delete Comment',
    deleteCommentConfirm: 'Are you sure you want to delete this comment?',
    deleteVideoTitle: 'Delete Video',
    deleteVideoConfirm: 'are you sure you want to delete?',
    deleteAccountConfirm: 'Your account and all videos will be deleted. Are you sure?',
    changePasswordHint: 'New password (min 6)',
    hintAboutYou: 'Tell about yourself...',
    aboutApp: 'App',
    webSite: 'Website',
    gmail: 'Email',
    pickEmailApp: 'Could not open email app',
  );
}
