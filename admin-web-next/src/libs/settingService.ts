// src/libs/settingService.ts

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

const getAuthHeaders = () => {
    const token = localStorage.getItem('token');
    return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
    };
};

export interface Profile {
    id: string;
    name: string;
    email: string;
    phone: string;
    birth_place: string;
    birth_date: string;
    address: string;
    photo_url: string;
    bank_name?: string;
    bank_account_number?: string;
}

export interface Company {
    id: string;
    name: string;
    address: string;
    email: string;
    phone: string;
    logo_url?: string;
}

export const settingService = {
    // 1. Profile Methods
    async getProfile() {
        const response = await fetch(`${API_URL}/profile`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal memuat profil.');
        return data.data as Profile;
    },

    async updateProfile(data: Partial<Profile>) {
        const response = await fetch(`${API_URL}/profile`, {
            method: 'PUT',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });
        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal memperbarui profil.');
        return resData.data;
    },

    // 2. Security Methods
    async requestOTP() {
        const response = await fetch(`${API_URL}/profile/request-otp`, {
            method: 'POST',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mengirim OTP.');
        return data;
    },

    async changePassword(data: { old_password?: string; otp_code?: string; new_password: string }) {
        const response = await fetch(`${API_URL}/profile/change-password`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });
        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal mengubah password.');
        return resData;
    },

    async changePIN(data: { old_pin?: string; otp_code?: string; new_pin: string }) {
        const response = await fetch(`${API_URL}/profile/change-pin`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });
        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal mengubah PIN.');
        return resData;
    },

    // 3. Company Methods
    async getCompany() {
        const response = await fetch(`${API_URL}/admin/company`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal memuat data perusahaan.');
        return data.data as Company;
    },

    async updateCompany(data: Partial<Company>) {
        const response = await fetch(`${API_URL}/admin/company`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });
        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal memperbarui instansi.');
        return resData.data;
    },

    // 4. Penalty Management (Non-absensi)
    async getPenalties() {
        const response = await fetch(`${API_URL}/admin/penalties`, {
            method: 'GET',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal memuat data denda.');
        return data.data;
    },

    async createPenalty(data: { user_id: string; amount: number; reason: string; date: string }) {
        const response = await fetch(`${API_URL}/admin/penalties`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(data),
        });
        const resData = await response.json();
        if (!response.ok) throw new Error(resData.message || 'Gagal menambahkan denda.');
        return resData.data;
    },

    async deletePenalty(id: string) {
        const response = await fetch(`${API_URL}/admin/penalties/${id}`, {
            method: 'DELETE',
            headers: getAuthHeaders(),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal menghapus denda.');
        return data;
    },

    // 5. Upload Method
    async uploadFile(file: File) {
        const token = localStorage.getItem('token');
        const formData = new FormData();
        formData.append('file', file);

        const response = await fetch(`${API_URL}/upload`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`
            },
            body: formData,
        });

        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Gagal mengunggah file.');
        return data.data; // Expecting { url: string }
    }
};
