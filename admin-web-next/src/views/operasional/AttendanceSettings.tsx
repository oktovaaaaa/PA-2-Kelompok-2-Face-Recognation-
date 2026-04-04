// src/views/operasional/AttendanceSettings.tsx
'use client'

import { useState, useEffect } from 'react'
import { 
  Card, CardHeader, CardContent, Grid, TextField, 
  Button, Typography, Box, CircularProgress, IconButton 
} from '@mui/material'
import { settingService, AttendanceSettings, PenaltyTier } from '@/libs/settingService'
import { useNotification } from '@/contexts/NotificationContext'

const AttendanceSettingsTab = () => {
  const { showNotification } = useNotification()
  const [settings, setSettings] = useState<AttendanceSettings | null>(null)
  const [loading, setLoading] = useState(true)
  const [saveLoading, setSaveLoading] = useState(false)

  const loadSettings = async () => {
    try {
      const data = await settingService.getAttendanceSettings()
      setSettings(data)
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadSettings()
  }, [])

  const handleSave = async () => {
    if (!settings) return
    setSaveLoading(true)
    try {
      await settingService.updateAttendanceSettings(settings)
      showNotification('Pengaturan absensi berhasil disimpan!', 'success')
      loadSettings()
    } catch (error) {
      showNotification('Gagal menyimpan pengaturan.', 'error')
    } finally {
      setSaveLoading(false)
    }
  }

  const addTier = () => {
    if (!settings) return
    const newTier: PenaltyTier = { late_minutes: 0, amount: 0 }
    setSettings({
      ...settings,
      late_tiers: [...(settings.late_tiers || []), newTier]
    })
  }

  const removeTier = (index: number) => {
    if (!settings) return
    const newTiers = [...settings.late_tiers]
    newTiers.splice(index, 1)
    setSettings({ ...settings, late_tiers: newTiers })
  }

  const updateTier = (index: number, field: keyof PenaltyTier, value: number) => {
    if (!settings) return
    const newTiers = [...settings.late_tiers]
    newTiers[index] = { ...newTiers[index], [field]: value }
    setSettings({ ...settings, late_tiers: newTiers })
  }

  if (loading) return <CircularProgress sx={{ display: 'block', m: 'auto', mt: 10 }} />

  return (
    <Grid container spacing={6}>
      {/* 1. Jam Kerja */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardHeader title="Jam Kerja & Toleransi" subheader="Atur jendela waktu absensi" />
          <CardContent>
            <Grid container spacing={4}>
              <Grid item xs={6}>
                <TextField 
                  fullWidth label="Check-in Start" type="time" InputLabelProps={{ shrink: true }}
                  value={settings?.check_in_start || ''}
                  onChange={e => setSettings(s => s ? {...s, check_in_start: e.target.value} : null)}
                />
              </Grid>
              <Grid item xs={6}>
                <TextField 
                  fullWidth label="Check-in End" type="time" InputLabelProps={{ shrink: true }}
                  value={settings?.check_in_end || ''}
                  onChange={e => setSettings(s => s ? {...s, check_in_end: e.target.value} : null)}
                />
              </Grid>
              <Grid item xs={6}>
                <TextField 
                  fullWidth label="Check-out Start" type="time" InputLabelProps={{ shrink: true }}
                  value={settings?.check_out_start || ''}
                  onChange={e => setSettings(s => s ? {...s, check_out_start: e.target.value} : null)}
                />
              </Grid>
              <Grid item xs={6}>
                <TextField 
                  fullWidth label="Check-out End" type="time" InputLabelProps={{ shrink: true }}
                  value={settings?.check_out_end || ''}
                  onChange={e => setSettings(s => s ? {...s, check_out_end: e.target.value} : null)}
                />
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Grid>

      {/* 2. Denda Dasar */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardHeader title="Kebijakan Denda Dasar" subheader="Denda standar absensi" />
          <CardContent>
            <Grid container spacing={4}>
              <Grid item xs={12}>
                <TextField 
                  fullWidth label="Denda Alpha (Rp)" type="number"
                  value={settings?.penalty_alpha || 0}
                  onChange={e => setSettings(s => s ? {...s, penalty_alpha: parseInt(e.target.value)} : null)}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField 
                  fullWidth label="Denda Telat Dasar (Rp)" type="number"
                  helperText="Denda yang langsung dikenakan saat telat 1 menit"
                  value={settings?.penalty_late_base || 0}
                  onChange={e => setSettings(s => s ? {...s, penalty_late_base: parseInt(e.target.value)} : null)}
                />
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Grid>

      {/* 3. Denda Berjenjang */}
      <Grid item xs={12}>
        <Card>
          <CardHeader 
            title="Denda Telat Berjenjang" 
            subheader="Tambahkan denda tambahan berdasarkan durasi keterlambatan"
            action={<Button startIcon={<i className='ri-add-line'/>} onClick={addTier}>Tambah Jenjang</Button>}
          />
          <CardContent>
            <Grid container spacing={4}>
              {settings?.late_tiers?.map((tier, idx) => (
                <Grid item xs={12} key={idx} sx={{ display: 'flex', gap: 4, alignItems: 'center' }}>
                  <Typography fontWeight="bold">{idx + 1}.</Typography>
                  <TextField 
                    label="Jika Telat > (Menit)" type="number" size="small"
                    value={tier.late_minutes}
                    onChange={e => updateTier(idx, 'late_minutes', parseInt(e.target.value))}
                  />
                  <TextField 
                    label="Denda Tambahan (Rp)" type="number" size="small"
                    value={tier.amount}
                    onChange={e => updateTier(idx, 'amount', parseInt(e.target.value))}
                  />
                  <IconButton color="error" onClick={() => removeTier(idx)}>
                    <i className="ri-delete-bin-line" />
                  </IconButton>
                </Grid>
              ))}
              {(!settings?.late_tiers || settings.late_tiers.length === 0) && (
                <Grid item xs={12}>
                  <Typography color="textSecondary" align="center" sx={{ py: 4 }}>
                    Belum ada denda berjenjang. Klik "Tambah Jenjang" untuk memulai.
                  </Typography>
                </Grid>
              )}
            </Grid>
          </CardContent>
        </Card>
      </Grid>

      {/* Save FAB/Button */}
      <Grid item xs={12} sx={{ display: 'flex', justifyContent: 'flex-end' }}>
        <Button 
          variant="contained" size="large" onClick={handleSave} disabled={saveLoading}
          startIcon={saveLoading ? <CircularProgress size={20}/> : <i className='ri-save-line'/>}
        >
          {saveLoading ? 'Menyimpan...' : 'Simpan Semua Pengaturan'}
        </Button>
      </Grid>
    </Grid>
  )
}

export default AttendanceSettingsTab
