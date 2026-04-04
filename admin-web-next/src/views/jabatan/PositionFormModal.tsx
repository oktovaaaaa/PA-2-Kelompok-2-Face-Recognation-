"use client"
// src/views/jabatan/PositionFormModal.tsx
import React, { useEffect, useState } from 'react'
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Typography,
  InputAdornment,
  CircularProgress
} from '@mui/material'
import { Position, employeeService } from '../../libs/employeeService'

interface Props {
  open: boolean
  onClose: () => void
  position: Position | null
  onSuccess: () => void
}

const PositionFormModal = ({ open, onClose, position, onSuccess }: Props) => {
  const [name, setName] = useState('')
  const [salary, setSalary] = useState('')
  const [loading, setLoading] = useState(false)

  const isEdit = !!position

  useEffect(() => {
    if (open) {
      if (position) {
        setName(position.name)
        setSalary(position.salary.toString())
      } else {
        setName('')
        setSalary('')
      }
    }
  }, [open, position])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!name || !salary) {
      return
    }

    setLoading(true)
    try {
      if (isEdit) {
        await employeeService.updatePosition(position.id, { name, salary: Number(salary) })
      } else {
        await employeeService.createPosition({ name, salary: Number(salary) })
      }
      onSuccess()
      onClose()
    } catch (error: any) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth='xs'>
      <DialogTitle fontWeight='700'>
        {isEdit ? 'Edit Jabatan' : 'Tambah Jabatan Baru'}
      </DialogTitle>
      <form onSubmit={handleSubmit}>
        <DialogContent dividers>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
            <Box>
                <Typography variant='caption' fontWeight='700' color='textSecondary' sx={{ mb: 1, display: 'block' }}>
                    NAMA JABATAN
                </Typography>
                <TextField
                    fullWidth
                    size='small'
                    placeholder='Contoh: Project Manager, HR Staff'
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    autoFocus
                />
            </Box>

            <Box>
                <Typography variant='caption' fontWeight='700' color='textSecondary' sx={{ mb: 1, display: 'block' }}>
                    GAJI POKOK
                </Typography>
                <TextField
                    fullWidth
                    size='small'
                    type='number'
                    placeholder='Contoh: 5000000'
                    value={salary}
                    onChange={(e) => setSalary(e.target.value)}
                    InputProps={{
                        startAdornment: <InputAdornment position="start">Rp</InputAdornment>,
                    }}
                />
            </Box>
          </Box>
        </DialogContent>
        <DialogActions sx={{ p: 4 }}>
          <Button onClick={onClose} disabled={loading} color='secondary'>Batal</Button>
          <Button 
            type='submit' 
            variant='contained' 
            disabled={loading}
            startIcon={loading && <CircularProgress size={16} color='inherit' />}
          >
            {isEdit ? 'Simpan Perubahan' : 'Tambah Jabatan'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  )
}

export default PositionFormModal
