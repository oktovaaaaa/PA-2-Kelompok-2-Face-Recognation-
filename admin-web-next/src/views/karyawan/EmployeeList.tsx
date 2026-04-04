// src/views/karyawan/EmployeeList.tsx
'use client'

import React, { useEffect, useState, useCallback } from 'react'
import {
  Card,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Typography,
  Button,
  CardHeader,
  IconButton,
  TextField,
  InputAdornment,
  Box,
  Avatar,
  Tab,
  Tabs,
  CircularProgress,
  TablePagination
} from '@mui/material'
import { employeeService, Employee } from '../../libs/employeeService'
import EmployeeDetailModal from './EmployeeDetailModal'
import PositionAssignModal from './PositionAssignModal'
import ConfirmDialog from '@/components/ConfirmDialog'
import { useNotification } from '@/contexts/NotificationContext'

const EmployeeList = () => {
  const { showNotification } = useNotification()
  
  // States
  const [employees, setEmployees] = useState<Employee[]>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState<'ACTIVE' | 'RESIGNED'>('ACTIVE')
  const [searchQuery, setSearchQuery] = useState('')
  
  // Modal States
  const [selectedEmployee, setSelectedEmployee] = useState<Employee | null>(null)
  const [isDetailOpen, setIsDetailOpen] = useState(false)
  const [isPositionOpen, setIsPositionOpen] = useState(false)
  const [isConfirmOpen, setIsConfirmOpen] = useState(false)
  const [confirmConfig, setConfirmConfig] = useState<{
    title: string, 
    message: string, 
    type: 'warning' | 'error' | 'info',
    action: () => void
  } | null>(null)

  // Pagination States
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const data = await employeeService.getEmployees(statusFilter)
      setEmployees(data || [])
      setPage(0)
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }, [statusFilter])

  useEffect(() => {
    loadData()
  }, [loadData])

  const handleOpenDetail = (emp: Employee) => {
    setSelectedEmployee(emp)
    setIsDetailOpen(true)
  }

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage)
  }

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10))
    setPage(0)
  }

  const handleAction = async (type: 'reset' | 'position' | 'status') => {
    if (!selectedEmployee) return

    if (type === 'reset') {
      setConfirmConfig({
        title: 'Reset Perangkat',
        type: 'warning',
        message: `Apakah Anda yakin ingin mereset perangkat untuk ${selectedEmployee.name}? Karyawan dapat login kembali dari HP baru.`,
        action: async () => {
          try {
            await employeeService.resetDevice(selectedEmployee.id)
            showNotification('Perangkat berhasil direset!', 'success')
            loadData()
          } catch (e) {
            showNotification('Gagal mereset perangkat.', 'error')
          }
        }
      })
      setIsConfirmOpen(true)
    } else if (type === 'position') {
      setIsPositionOpen(true)
    } else if (type === 'status') {
      const isFiring = selectedEmployee.status === 'ACTIVE'
      setConfirmConfig({
        title: isFiring ? 'Pecat Karyawan' : 'Aktifkan Kembali',
        type: isFiring ? 'error' : 'info',
        message: isFiring 
          ? `Apakah Anda yakin ingin memecat ${selectedEmployee.name}? Status akan menjadi RESIGNED.` 
          : `Aktifkan kembali ${selectedEmployee.name}?`,
        action: async () => {
          try {
             if (isFiring) await employeeService.fireEmployee(selectedEmployee.id)
             else await employeeService.reactivateEmployee(selectedEmployee.id)
             showNotification(isFiring ? 'Karyawan telah dinonaktifkan.' : 'Karyawan telah diaktifkan kembali.', 'success')
             loadData()
          } catch (e) {
             showNotification('Gagal memproses aksi status.', 'error')
          }
        }
      })
      setIsConfirmOpen(true)
    }
  }

  const handleAssignPosition = async (posId: string) => {
    if (!selectedEmployee) return
    try {
        await employeeService.assignPosition(selectedEmployee.id, posId)
        setIsPositionOpen(false)
        showNotification('Jabatan berhasil diperbarui!', 'success')
        loadData()
        const updated = employees.find(e => e.id === selectedEmployee.id)
        if (updated) setSelectedEmployee({...updated, position_id: posId})
    } catch (error) {
        showNotification('Gagal memperbarui jabatan.', 'error')
    }
  }

  const filteredEmployees = employees.filter(emp => 
    emp.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    emp.email.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const paginatedEmployees = filteredEmployees.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <Card sx={{ border: '1px solid', borderColor: 'divider' }}>
        <CardHeader 
          title="Data Karyawan" 
          subheader={`Kelola data dan status ${employees.length} karyawan`}
          sx={{ pb: 0 }}
        />
        <Box sx={{ px: 5, py: 4, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 4, flexWrap: 'wrap' }}>
          <Tabs 
            value={statusFilter} 
            onChange={(_, val) => setStatusFilter(val)}
            sx={{ borderBottom: 0 }}
          >
            <Tab label="Aktif" value="ACTIVE" />
            <Tab label="Diberhentikan" value="RESIGNED" />
          </Tabs>
          
          <TextField
            size='small'
            placeholder='Cari Nama / Email...'
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            sx={{ width: { xs: '100%', sm: 300 } }}
            InputProps={{
              startAdornment: (
                <InputAdornment position='start'>
                  <i className='ri-search-line' />
                </InputAdornment>
              )
            }}
          />
        </Box>
      </Card>

      <Card>
        <TableContainer component={Paper} elevation={0}>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', p: 10 }}>
              <CircularProgress size={40} />
            </Box>
          ) : (
            <Table sx={{ minWidth: 800 }}>
              <TableHead sx={{ bgcolor: 'action.hover' }}>
                <TableRow>
                  <TableCell sx={{ fontWeight: '600' }}>Karyawan</TableCell>
                  <TableCell sx={{ fontWeight: '600' }}>Email</TableCell>
                  <TableCell sx={{ fontWeight: '600' }}>Jabatan</TableCell>
                  <TableCell align="center" sx={{ fontWeight: '600' }}>Status</TableCell>
                  <TableCell align="right" sx={{ fontWeight: '600' }}>Aksi</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {paginatedEmployees.length === 0 ? (
                    <TableRow>
                        <TableCell colSpan={5} align='center' sx={{ py: 10 }}>
                            <Typography color='textSecondary'>Tidak ada data karyawan ditemukan.</Typography>
                        </TableCell>
                    </TableRow>
                ) : paginatedEmployees.map((row) => (
                  <TableRow 
                    key={row.id} 
                    hover 
                    onClick={() => handleOpenDetail(row)}
                    sx={{ cursor: 'pointer', '&:last-child td, &:last-child th': { border: 0 } }}
                  >
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <Avatar 
                          src={row.photo_url ? `http://localhost:8080${row.photo_url}` : undefined}
                          sx={{ mr: 3, width: 34, height: 34 }} 
                        >
                          {row.name.charAt(0)}
                        </Avatar>
                        <Typography variant='body2' fontWeight="600" color='text.primary'>{row.name}</Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                        <Typography variant='body2'>{row.email}</Typography>
                    </TableCell>
                    <TableCell>
                      <Chip 
                        label={row.position_name || 'Unassigned'} 
                        size='small' 
                        variant='outlined'
                        sx={{ bgcolor: 'background.paper', color: 'primary.main' }}
                        color={row.position_name ? 'primary' : 'default'}
                      />
                    </TableCell>
                    <TableCell align="center">
                      <Chip 
                        label={row.status === 'ACTIVE' ? 'Aktif' : 'Nonaktif'} 
                        color={row.status === 'ACTIVE' ? 'success' : 'error'} 
                        size='small' 
                        variant='outlined'
                      />
                    </TableCell>
                    <TableCell align="right">
                      <IconButton color='primary' size='small' onClick={(e) => { e.stopPropagation(); handleOpenDetail(row); }}>
                        <i className='ri-eye-line' />
                      </IconButton>
                      <IconButton color='error' size='small' onClick={(e) => { e.stopPropagation(); setSelectedEmployee(row); handleAction('status'); }}>
                        <i className={row.status === 'ACTIVE' ? 'ri-user-unfollow-line' : 'ri-user-add-line'} />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </TableContainer>
        <TablePagination
          rowsPerPageOptions={[5, 10, 25]}
          component='div'
          count={filteredEmployees.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage="Baris per halaman:"
        />
      </Card>

      {/* Modals & Dialogs */}
      <EmployeeDetailModal 
        open={isDetailOpen} 
        onClose={() => setIsDetailOpen(false)} 
        employee={selectedEmployee}
        onAction={handleAction}
      />

      <PositionAssignModal 
        open={isPositionOpen}
        onClose={() => setIsPositionOpen(false)}
        employeeName={selectedEmployee?.name || ''}
        currentPositionId={selectedEmployee?.position_id}
        onAssign={handleAssignPosition}
      />

      <ConfirmDialog 
        open={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={confirmConfig?.action || (() => {})}
        title={confirmConfig?.title || ''}
        message={confirmConfig?.message || ''}
        type={confirmConfig?.type}
      />
    </Box>
  )
}

export default EmployeeList
