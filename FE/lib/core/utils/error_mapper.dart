// lib/core/utils/error_mapper.dart

class ErrorMapper {
  static String map(dynamic error) {
    final message = error.toString();

    if (message.contains('SocketException')) {
      return 'Tidak dapat terhubung ke server. Pastikan backend aktif dan IP benar.';
    }

    if (message.contains('ACCOUNT_ALREADY_ACTIVE_ON_ANOTHER_DEVICE')) {
      return 'Akun ini sudah aktif di perangkat lain.';
    }

    if (message.contains('Email sudah terdaftar')) {
      return 'Email sudah terdaftar.';
    }

    if (message.contains('Password salah')) {
      return 'Password yang Anda masukkan salah.';
    }

    if (message.contains('User tidak ditemukan') ||
        message.contains('Email tidak ditemukan')) {
      return 'Akun tidak ditemukan.';
    }

    if (message.contains('OTP sudah kadaluarsa')) {
      return 'Kode OTP sudah kadaluarsa.';
    }

    if (message.contains('Kode OTP salah')) {
      return 'Kode OTP yang dimasukkan salah.';
    }

    if (message.contains('Token undangan tidak valid')) {
      return 'Token undangan tidak valid.';
    }

    if (message.contains('Token sudah digunakan')) {
      return 'Token undangan sudah digunakan.';
    }

    if (message.contains('Akun masih menunggu persetujuan admin')) {
      return 'Akun Anda masih menunggu persetujuan admin.';
    }

    if (message.contains('Akun ditolak oleh admin')) {
      return 'Akun Anda ditolak oleh admin.';
    }

    if (message.contains('PIN salah')) {
      return 'PIN yang Anda masukkan salah.';
    }

    return message.isEmpty ? 'Terjadi kesalahan.' : message;
  }
}