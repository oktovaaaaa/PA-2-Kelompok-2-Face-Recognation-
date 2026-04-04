// src/views/cuti/LeaveDetailModal.tsx
'use client'

import React, { useState } from 'react'
import Dialog from '@mui/material/Dialog'
import DialogTitle from '@mui/material/DialogTitle'
import DialogContent from '@mui/material/DialogContent'
import DialogActions from '@mui/material/DialogActions'
import Button from '@mui/material/Button'
import Typography from '@mui/material/Typography'
import Box from '@mui/material/Box'
import Avatar from '@mui/material/Avatar'
import Chip from '@mui/material/Chip'
import TextField from '@mui/material/TextField'
import Divider from '@mui/material/Divider'
import Grid from '@mui/material/Grid'
import { LeaveRequest } from '@/libs/leaveService'
import { format } from 'date-fns'

interface Props {
  open: boolean
  onClose: () => void
  leave: LeaveRequest | null
  onProcess: (id: string, action: 'approve' | 'reject', note: string) => void
}

const LeaveDetailModal = ({ open, onClose, leave, onProcess }: Props) => {
  const [note, setNote] = useState('')

  if (!leave) return null

  const isPending = leave.status === 'PENDING'

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth='sm'>
      <DialogTitle sx={{ pb: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Typography variant='h6' fontWeight='600'>Detail Pengajuan Izin</Typography>
          <Chip 
            label={leave.status === 'APPROVED' ? 'Disetujui' : leave.status === 'REJECTED' ? 'Ditolak' : 'Menunggu'}
            size='small'
            color={leave.status === 'APPROVED' ? 'success' : leave.status === 'REJECTED' ? 'error' : 'warning'}
            variant='tonal'
          />
        </Box>
      </DialogTitle>
      
      <DialogContent dividers>
        {/* User Info */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 4, mb: 6 }}>
          <Avatar 
            src={leave.user_photo ? `http://localhost:8080${leave.user_photo}` : undefined}
            sx={{ width: 60, height: 60 }}
          >
            {leave.user_name?.charAt(0)}
          </Avatar>
          <Box>
            <Typography variant='subtitle1' fontWeight='600'>{leave.user_name}</Typography>
            <Typography variant='body2' color='text.secondary'>{leave.user_email}</Typography>
          </Box>
        </Box>

        <Grid container spacing={4}>
          <Grid item xs={6}>
            <Typography variant='caption' color='text.secondary'>Tipe Izin</Typography>
            <Typography variant='body1' fontWeight='600'>{leave.type}</Typography>
          </Grid>
          <Grid item xs={6}>
            <Typography variant='caption' color='text.secondary'>Tanggal Pengajuan</Typography>
            <Typography variant='body1' fontWeight='600'>{format(new Date(leave.created_at), 'dd MMMM yyyy')}</Typography>
          </Grid>
          <Grid item xs={12}>
            <Typography variant='caption' color='text.secondary'>Judul / Alasan</Typography>
            <Typography variant='body1' fontWeight='600' sx={{ mb: 2 }}>{leave.title}</Typography>
            <Box sx={{ p: 3, bgcolor: 'action.hover', borderRadius: 1 }}>
              <Typography variant='body2'>{leave.description || 'Tidak ada deskripsi.'}</Typography>
            </Box>
          </Grid>
          
          {leave.photo_url && (
            <Grid item xs={12}>
                <Typography variant='caption' color='text.secondary'>Bukti Foto</Typography>
                <Box 
                    component="img" 
                    src={`http://localhost:8080${leave.photo_url}`} 
                    sx={{ width: '100%', maxHeight: 300, objectFit: 'contain', borderRadius: 2, mt: 2, border: theme => `1px solid ${theme.palette.divider}` }}
                    alt="Bukti Izin"
                />
            </Grid>
          )}

          {leave.admin_note && (
             <Grid item xs={12}>
                <Divider sx={{ my: 4 }} />
                <Typography variant='caption' color='text.secondary'>Catatan Admin</Typography>
                <Typography variant='body2' sx={{ fontStyle: 'italic' }}>{leave.admin_note}</Typography>
             </Grid>
          )}
        </Grid>

        {isPending && (
          <Box sx={{ mt: 8 }}>
            <TextField
              fullWidth
              multiline
              rows={3}
              placeholder='Tambahkan catatan balasan (opsional)...'
              value={note}
              onChange={(e) => setNote(e.target.value)}
              label="Catatan Admin"
            />
          </Box>
        )}
      </DialogContent>

      <DialogActions sx={{ p: 4 }}>
        <Button onClick={onClose} color='secondary'>Tutup</Button>
        {isPending && (
          <>
            <Button 
                variant='outlined' 
                color='error' 
                onClick={() => onProcess(leave.id, 'reject', note)}
            >
                Tolak
            </Button>
            <Button 
                variant='contained' 
                color='success' 
                onClick={() => onProcess(leave.id, 'approve', note)}
            >
                Setujui
            </Button>
          </>
        )}
      </DialogActions>
    </Dialog>
  )
}

export default LeaveDetailModal
