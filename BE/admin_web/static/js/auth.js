// BE/admin_web/static/js/auth.js

const auth = {
    // Step 1: Kirim OTP Login
    async loginStep1(email, password) {
        try {
            await api.post('/auth/login', { email, password, isAdminPanel: true });
            
            Swal.fire({
                icon: 'success',
                title: 'OTP Dikirim',
                text: 'Kode verifikasi telah dikirim ke email Anda.',
                timer: 2000,
                showConfirmButton: false
            });
            
            return true;
        } catch (error) {
            Swal.fire({
                icon: 'error',
                title: 'Login Gagal',
                text: error.message || 'Email atau password salah.'
            });
            throw error;
        }
    },

    // Step 2: Verifikasi OTP & Login Berhasil
    async loginStep2(email, code) {
        try {
            const data = await api.post('/auth/verify-login-otp', { 
                email, 
                code, 
                device_id: 'WEB-ADMIN-DASHBOARD' 
            });
            
            if (data.role !== 'ADMIN') {
                localStorage.clear();
                Swal.fire({
                    icon: 'warning',
                    title: 'Akses Terbatas',
                    text: 'Akun ini tidak terdaftar sebagai Administrator.',
                    confirmButtonColor: '#0F172A'
                });
                return false;
            }

            localStorage.setItem('token', data.token);
            localStorage.setItem('user_id', data.userId);
            localStorage.setItem('user_name', data.email.split('@')[0]);
            localStorage.setItem('role', data.role);
            localStorage.setItem('company_id', data.companyId);

            Swal.fire({
                icon: 'success',
                title: 'Berhasil Masuk!',
                text: 'Mengarahkan ke Dashboard Admin...',
                timer: 1500,
                showConfirmButton: false
            });

            setTimeout(() => {
                window.location.href = '/admin-web/dashboard';
            }, 1500);
            return true;
        } catch (error) {
            Swal.fire({
                icon: 'error',
                title: 'Verifikasi Gagal',
                text: error.message || 'Kode OTP tidak valid.',
                confirmButtonColor: '#2563EB'
            });
            throw error;
        }
    },

    // Registrasi Admin Baru
    async register(name, email, password, companyName, otpCode) {
        try {
            await api.post('/auth/register-admin', {
                name,
                email,
                password,
                companyName,
                otpCode
            });
            
            Swal.fire({
                icon: 'success',
                title: 'Pendaftaran Berhasil',
                text: 'Akun admin telah dibuat. Silakan login.',
                confirmButtonColor: '#2563EB'
            });
            
            return true;
        } catch (error) {
            Swal.fire({
                icon: 'error',
                title: 'Registrasi Gagal',
                text: error.message || 'Terjadi kesalahan saat mendaftar.',
                confirmButtonColor: '#EF4444'
            });
            throw error;
        }
    },

    // Lupa Sandi Step 1
    async requestResetOTP(email) {
        try {
            await api.post('/auth/forgot-password', { email });
            
            Swal.fire({
                icon: 'success',
                title: 'Email Terkirim',
                text: 'Kode reset telah dikirim ke ' + email,
                confirmButtonColor: '#2563EB'
            });
            
            return true;
        } catch (error) {
            Swal.fire({
                icon: 'error',
                title: 'Gagal',
                text: error.message || 'Email tidak ditemukan.',
                confirmButtonColor: '#EF4444'
            });
            throw error;
        }
    },

    // Lupa Sandi Step 2: Ganti Password
    async resetPassword(email, code, newPassword) {
        try {
            await api.post('/auth/reset-password', { 
                email, 
                code, 
                newPassword 
            });
            
            await Swal.fire({
                icon: 'success',
                title: 'Berhasil',
                text: 'Kata sandi Anda telah diperbarui. Silakan login kembali.',
                confirmButtonText: 'Login Sekarang'
            });
            
            return true;
        } catch (error) {
            Swal.fire({
                icon: 'error',
                title: 'Reset Gagal',
                text: error.message || 'Kode OTP salah atau terjadi kesalahan.'
            });
            throw error;
        }
    },

    logout() {
        Swal.fire({
            title: 'Konfirmasi Keluar',
            text: "Apakah Anda yakin ingin keluar dari sistem?",
            icon: 'question',
            showCancelButton: true,
            confirmButtonColor: '#2563EB',
            cancelButtonColor: '#64748B',
            confirmButtonText: 'Ya, Keluar',
            cancelButtonText: 'Batal'
        }).then((result) => {
            if (result.isConfirmed) {
                localStorage.clear();
                window.location.href = '/admin-web/login';
            }
        });
    },

    checkAuth() {
        const token = localStorage.getItem('token');
        const isLoginPath = window.location.pathname.includes('/login');

        if (!token && !isLoginPath) {
            window.location.href = '/admin-web/login';
        } else if (token && isLoginPath) {
            window.location.href = '/admin-web/dashboard';
        }
    }
};

// Cek autentikasi jika bukan halaman login
if (!window.location.pathname.includes('/login')) {
    auth.checkAuth();
}
