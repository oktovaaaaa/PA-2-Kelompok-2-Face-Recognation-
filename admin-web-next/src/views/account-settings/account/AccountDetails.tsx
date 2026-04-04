// src/views/account-settings/account/AccountDetails.tsx
'use client'

import { useState, useEffect, ChangeEvent } from 'react'
import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Button from '@mui/material/Button'
import Typography from '@mui/material/Typography'
import TextField from '@mui/material/TextField'
import CircularProgress from '@mui/material/CircularProgress'
import { settingService, Profile } from '@/libs/settingService'
import { useNotification } from '@/contexts/NotificationContext'

const AccountDetails = () => {
  const [formData, setFormData] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const [saveLoading, setSaveLoading] = useState(false)
  const [imgSrc, setImgSrc] = useState<string>('/images/avatars/1.png')
  const { showNotification } = useNotification()

  const baseUrl = process.env.NEXT_PUBLIC_API_URL?.replace('/api', '') || 'http://localhost:8080'

  const loadProfile = async () => {
    try {
      const data = await settingService.getProfile()
      setFormData(data)
      if (data.photo_url) {
        setImgSrc(`${baseUrl}${data.photo_url}`)
      }
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadProfile()
  }, [])

  const handleFormChange = (field: keyof Profile, value: string) => {
    if (formData) {
      setFormData({ ...formData, [field]: value })
    }
  }

  const handleFileInputChange = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file && formData) {
      setSaveLoading(true)
      try {
        const res = await settingService.uploadFile(file)
        const photoUrl = res.url
        await settingService.updateProfile({ ...formData, photo_url: photoUrl })
        setImgSrc(`${baseUrl}${photoUrl}`)
        setFormData({ ...formData, photo_url: photoUrl })
        showNotification('Foto profil berhasil diperbarui!', 'success')
      } catch (error) {
        showNotification('Gagal mengunggah foto.', 'error')
      } finally {
        setSaveLoading(false)
      }
    }
  }

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!formData) return
    setSaveLoading(true)
    try {
      await settingService.updateProfile(formData)
      showNotification('Profil berhasil diperbarui!', 'success')
    } catch (error) {
      showNotification('Gagal memperbarui profil.', 'error')
    } finally {
      setSaveLoading(false)
    }
  }

  if (loading) return <CircularProgress sx={{ display: 'block', m: 'auto', mt: 10 }} />

  return (
    <Card>
      <CardContent className='mbe-5'>
        <div className='flex max-sm:flex-col items-center gap-6'>
          <img height={100} width={100} className='rounded bg-slate-100 object-cover' src={imgSrc} alt='Profile' />
          <div className='flex flex-grow flex-col gap-4'>
            <div className='flex flex-col sm:flex-row gap-4'>
              <Button component='label' size='small' variant='contained' htmlFor='account-settings-upload-image'>
                Upload New Photo
                <input hidden type='file' accept='image/*' onChange={handleFileInputChange} id='account-settings-upload-image' />
              </Button>
            </div>
            <Typography>Allowed JPG, GIF or PNG. Max size of 800K</Typography>
          </div>
        </div>
      </CardContent>
      <CardContent>
        <form onSubmit={handleSave}>
          <Grid container spacing={5}>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Nama Lengkap' 
                value={formData?.name || ''} 
                onChange={e => handleFormChange('name', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Email' 
                value={formData?.email || ''} 
                disabled
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Nomor Telepon' 
                value={formData?.phone || ''} 
                onChange={e => handleFormChange('phone', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Tempat Lahir' 
                value={formData?.birth_place || ''} 
                onChange={e => handleFormChange('birth_place', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Tanggal Lahir' 
                type='date'
                InputLabelProps={{ shrink: true }}
                value={formData?.birth_date || ''} 
                onChange={e => handleFormChange('birth_date', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField 
                fullWidth label='Alamat' 
                value={formData?.address || ''} 
                onChange={e => handleFormChange('address', e.target.value)} 
              />
            </Grid>
            <Grid item xs={12} className='flex gap-4 flex-wrap'>
              <Button variant='contained' type='submit' disabled={saveLoading}>
                {saveLoading ? 'Menyimpan...' : 'Simpan Perubahan'}
              </Button>
              <Button variant='outlined' color='secondary' onClick={loadProfile}>
                Batalkan
              </Button>
            </Grid>
          </Grid>
        </form>
      </CardContent>
    </Card>
  )
}

export default AccountDetails
