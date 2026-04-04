// src/views/operasional/PenaltyManager.tsx
'use client'

import { useState, useEffect, useCallback } from 'react'
import { 
  Card, CardHeader, CardContent, Grid, TextField, 
  Button, Typography, Box, CircularProgress, IconButton,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  Paper, Avatar, MenuItem, Chip
} from '@mui/material'
import { settingService, ManualPenalty } from '@/libs/settingService'
import { employeeService, Employee } from '@/libs/employeeService'
import { format } from 'date-fns'
import { useNotification } from '@/contexts/NotificationContext'
import ConfirmDialog from '@/components/ConfirmDialog'

const PenaltyManager = () => {
  const { showNotification } = useNotification()
  const [penalties, setPenalties] = useState<ManualPenalty[]>([])
  const [employees, setEmployees] = useState<Employee[]>([])
  const [loading, setLoading] = useState(true)
  const [saveLoading, setSaveLoading] = useState(false)
  
  // Form State
  const [formData, setFormData] = useState({ user_id: '', title: '', amount: 0, date: format(new Date(), 'yyyy-MM-dd') })
  
  // Confirm Dialog State
  const [isConfirmOpen, setIsConfirmOpen] = useState(false)
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const [pData, eData] = await Promise.all([
        settingService.getManualPenalties(),
        employeeService.getEmployees('ACTIVE')
      ])
      setPenalties(pData || [])
      setEmployees(eData || [])
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadData()
  }, [loadData])

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!formData.user_id || !formData.amount) return
    setSaveLoading(true)
    try {
      await settingService.createManualPenalty(formData)
      showNotification('Denda berhasil ditambahkan!', 'success')
      setFormData({ user_id: '', title: '', amount: 0, date: format(new Date(), 'yyyy-MM-dd') })
      loadData()
    } catch (error) {
      showNotification('Gagal menambahkan denda.', 'error')
    } finally {
      setSaveLoading(false)
    }
  }

  const handleDelete = async (id: string) => {
    setSelectedId(id)
    setIsConfirmOpen(true)
  }

  const confirmDelete = async () => {
    if (!selectedId) return
    try {
      await settingService.deletePenalty(selectedId)
      showNotification('Data denda berhasil dihapus.', 'success')
      loadData()
    } catch (error) {
      showNotification('Gagal menghapus data.', 'error')
    }
  }

  if (loading) return <CircularProgress sx={{ display: 'block', m: 'auto', mt: 10 }} />

  return (
    <Grid container spacing={6}>
      {/* 1. Form Input */}
      <Grid item xs={12} md={4}>
        <Card>
          <CardHeader title="Catat Pelanggaran" subheader="Berikan denda manual non-absensi" />
          <CardContent>
            <form onSubmit={handleAdd}>
              <Grid container spacing={4}>
                <Grid item xs={12}>
                  <TextField
                    select fullWidth label="Karyawan" size="small" required
                    value={formData.user_id}
                    onChange={e => setFormData({...formData, user_id: e.target.value})}
                  >
                    {employees.map(emp => (
                      <MenuItem key={emp.id} value={emp.id}>{emp.name}</MenuItem>
                    ))}
                  </TextField>
                </Grid>
                <Grid item xs={12}>
                  <TextField 
                    fullWidth label="Judul / Jenis Pelanggaran" size="small" required
                    placeholder="Misal: Merusak fasilitas, Tidak pakai seragam"
                    value={formData.title}
                    onChange={e => setFormData({...formData, title: e.target.value})}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField 
                    fullWidth label="Jumlah Denda (Rp)" type="number" size="small" required
                    value={formData.amount}
                    onChange={e => setFormData({...formData, amount: parseInt(e.target.value)})}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField 
                    fullWidth label="Tanggal" type="date" size="small" required
                    InputLabelProps={{ shrink: true }}
                    value={formData.date}
                    onChange={e => setFormData({...formData, date: e.target.value})}
                  />
                </Grid>
                <Grid item xs={12}>
                  <Button type="submit" variant="contained" fullWidth disabled={saveLoading}>
                    {saveLoading ? 'Memproses...' : 'Kirim Denda'}
                  </Button>
                </Grid>
              </Grid>
            </form>
          </CardContent>
        </Card>
      </Grid>

      {/* 2. History Table */}
      <Grid item xs={12} md={8}>
        <Card>
          <CardHeader title="Riwayat Pelanggaran Terbaru" />
          <TableContainer component={Paper} elevation={0}>
            <Table>
              <TableHead sx={{ bgcolor: 'action.hover' }}>
                <TableRow>
                  <TableCell>Karyawan</TableCell>
                  <TableCell>Jenis Pelanggaran</TableCell>
                  <TableCell>Jumlah</TableCell>
                  <TableCell>Tanggal</TableCell>
                  <TableCell align="right">Aksi</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {penalties.map((row) => (
                  <TableRow key={row.id}>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Avatar sx={{ width: 28, height: 28, fontSize: '0.8rem' }}>{row.user_name?.charAt(0)}</Avatar>
                        <Typography variant="body2">{row.user_name}</Typography>
                      </Box>
                    </TableCell>
                    <TableCell><Typography variant="body2">{row.title}</Typography></TableCell>
                    <TableCell><Typography variant="body2" color="error" fontWeight="bold">Rp {row.amount.toLocaleString()}</Typography></TableCell>
                    <TableCell><Typography variant="body2">{format(new Date(row.date), 'dd MMM yyyy')}</Typography></TableCell>
                    <TableCell align="right">
                      <IconButton size="small" color="error" onClick={() => handleDelete(row.id)}>
                        <i className="ri-delete-bin-line" />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
                {penalties.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={5} align="center" sx={{ py: 6 }}>Belum ada data pelanggaran.</TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </Card>
      </Grid>

      <ConfirmDialog 
        open={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={confirmDelete}
        title="Hapus Data Denda"
        message="Denda yang dihapus tidak dapat dikembalikan. Lanjutkan?"
        type="error"
      />
    </Grid>
  )
}

export default PenaltyManager
