// src/views/account-settings/security/index.tsx
'use client'

import { useState } from 'react'
import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardHeader from '@mui/material/CardHeader'
import CardContent from '@mui/material/CardContent'
import Button from '@mui/material/Button'
import TextField from '@mui/material/TextField'
import InputAdornment from '@mui/material/InputAdornment'
import IconButton from '@mui/material/IconButton'
import { settingService } from '@/libs/settingService'
import { useNotification } from '@/contexts/NotificationContext'

const SecurityTab = () => {
  const { showNotification } = useNotification()
  
  // Password States
  const [showOldPassword, setShowOldPassword] = useState(false)
  const [showNewPassword, setShowNewPassword] = useState(false)
  const [passwordData, setPasswordData] = useState({ old: '', new: '', otp: '' })
  
  // PIN States
  const [pinData, setPinData] = useState({ old: '', new: '', otp: '' })
  
  const [loading, setLoading] = useState(false)

  const handleRequestOTP = async () => {
    setLoading(true)
    try {
      await settingService.requestOTP()
      showNotification('Kode OTP telah dikirim ke email Anda.', 'info')
    } catch (error) {
      showNotification('Gagal mengirim OTP.', 'error')
    } finally {
      setLoading(false)
    }
  }

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!passwordData.new) return showNotification('Password baru wajib diisi.', 'warning')
    setLoading(true)
    try {
      await settingService.changePassword({
        old_password: passwordData.old || undefined,
        otp_code: passwordData.otp || undefined,
        new_password: passwordData.new
      })
      showNotification('Password berhasil diperbarui!', 'success')
      setPasswordData({ old: '', new: '', otp: '' })
    } catch (error: any) {
      showNotification(error.message || 'Gagal mengubah password.', 'error')
    } finally {
      setLoading(false)
    }
  }

  const handleChangePIN = async (e: React.FormEvent) => {
    e.preventDefault()
    if (pinData.new.length !== 6) return showNotification('PIN harus 6 digit angka.', 'warning')
    setLoading(true)
    try {
      await settingService.changePIN({
        old_pin: pinData.old || undefined,
        otp_code: pinData.otp || undefined,
        new_pin: pinData.new
      })
      showNotification('PIN berhasil diperbarui!', 'success')
      setPinData({ old: '', new: '', otp: '' })
    } catch (error: any) {
      showNotification(error.message || 'Gagal mengubah PIN.', 'error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Grid container spacing={6}>
      <Grid item xs={12}>
        <Card>
          <CardHeader title='Ganti Password' subheader='Pastikan menggunakan kombinasi karakter yang kuat.' />
          <CardContent>
            <form onSubmit={handleChangePassword}>
              <Grid container spacing={5}>
                <Grid item xs={12} sm={6}>
                  <TextField
                    fullWidth
                    label='Password Lama'
                    type={showOldPassword ? 'text' : 'password'}
                    value={passwordData.old}
                    onChange={e => setPasswordData({ ...passwordData, old: e.target.value })}
                    InputProps={{
                      endAdornment: (
                        <InputAdornment position='end'>
                          <IconButton onClick={() => setShowOldPassword(!showOldPassword)}>
                            <i className={showOldPassword ? 'ri-eye-off-line' : 'ri-eye-line'} />
                          </IconButton>
                        </InputAdornment>
                      )
                    }}
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField 
                    fullWidth label='Password Baru' 
                    type={showNewPassword ? 'text' : 'password'}
                    value={passwordData.new}
                    onChange={e => setPasswordData({ ...passwordData, new: e.target.value })}
                    InputProps={{
                        endAdornment: (
                          <InputAdornment position='end'>
                            <IconButton onClick={() => setShowNewPassword(!showNewPassword)}>
                              <i className={showNewPassword ? 'ri-eye-off-line' : 'ri-eye-line'} />
                            </IconButton>
                          </InputAdornment>
                        )
                      }}
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField 
                    fullWidth label='Kode OTP (Opsional)' 
                    helperText='Gunakan OTP jika lupa password lama.'
                    value={passwordData.otp}
                    onChange={e => setPasswordData({ ...passwordData, otp: e.target.value })}
                  />
                </Grid>
                <Grid item xs={12} className='flex gap-4 items-center'>
                  <Button variant='contained' type='submit' disabled={loading}>
                    {loading ? 'Memproses...' : 'Ubah Password'}
                  </Button>
                  <Button variant='outlined' color='secondary' onClick={handleRequestOTP}>
                    Minta Kode OTP
                  </Button>
                </Grid>
              </Grid>
            </form>
          </CardContent>
        </Card>
      </Grid>

      <Grid item xs={12}>
        <Card>
          <CardHeader title='Ganti PIN Transaksi' subheader='PIN digunakan untuk verifikasi cepat di aplikasi mobile.' />
          <CardContent>
            <form onSubmit={handleChangePIN}>
              <Grid container spacing={5}>
                <Grid item xs={12} sm={6}>
                  <TextField 
                    fullWidth label='PIN Lama' 
                    type='password'
                    value={pinData.old}
                    onChange={e => setPinData({ ...pinData, old: e.target.value })}
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField 
                    fullWidth label='PIN Baru (6 Digit)' 
                    inputProps={{ maxLength: 6 }}
                    value={pinData.new}
                    onChange={e => setPinData({ ...pinData, new: e.target.value })}
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField 
                    fullWidth label='Kode OTP (Opsional)' 
                    helperText='Gunakan OTP jika lupa PIN lama.'
                    value={pinData.otp}
                    onChange={e => setPinData({ ...pinData, otp: e.target.value })}
                  />
                </Grid>
                <Grid item xs={12} className='flex gap-4 items-center'>
                  <Button variant='contained' color='info' type='submit' disabled={loading}>
                    {loading ? 'Memproses...' : 'Ubah PIN'}
                  </Button>
                  <Button variant='outlined' color='info' onClick={handleRequestOTP}>
                    Minta Kode OTP
                  </Button>
                </Grid>
              </Grid>
            </form>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  )
}

export default SecurityTab
