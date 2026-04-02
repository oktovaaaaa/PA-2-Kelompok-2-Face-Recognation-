// BE/admin_web/static/js/api.js

const API_BASE = '/api';

const api = {
    async request(url, options = {}) {
        const token = localStorage.getItem('token');
        const headers = {
            'Content-Type': 'application/json',
            ...options.headers,
        };

        if (token) {
            headers['Authorization'] = `Bearer ${token}`;
        }

        try {
            const response = await fetch(`${API_BASE}${url}`, {
                ...options,
                headers,
            });

            const result = await response.json();

            if (!response.ok) {
                // Handle unauthorized
                if (response.status === 401 && !window.location.pathname.includes('/login')) {
                    localStorage.clear();
                    window.location.href = '/admin-web/login';
                }
                throw new Error(result.message || 'Terjadi kesalahan');
            }

            return result.data;
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    },

    get(url) {
        return this.request(url, { method: 'GET' });
    },

    post(url, body) {
        return this.request(url, {
            method: 'POST',
            body: JSON.stringify(body),
        });
    },

    put(url, body) {
        return this.request(url, {
            method: 'PUT',
            body: JSON.stringify(body),
        });
    },

    delete(url) {
        return this.request(url, { method: 'DELETE' });
    }
};
