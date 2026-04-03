// src/views/karyawan/EmployeeList.tsx
import React from 'react'
import Card from '@mui/material/Card'
import Table from '@mui/material/Table'
import TableBody from '@mui/material/TableBody'
import TableCell from '@mui/material/TableCell'
import TableContainer from '@mui/material/TableContainer'
import TableHead from '@mui/material/TableHead'
import TableRow from '@mui/material/TableRow'
import Paper from '@mui/material/Paper'
import Chip from '@mui/material/Chip'
import Typography from '@mui/material/Typography'
import Button from '@mui/material/Button'
import { CardHeader, IconButton } from '@mui/material'

const mockEmployees = [
  { id: 1, name: 'Budi Santoso', email: 'budi@gmail.com', role: 'Staff', status: 'ACTIVE' },
  { id: 2, name: 'Siti Aminah', email: 'siti@gmail.com', role: 'Manager', status: 'ACTIVE' },
  { id: 3, name: 'Andi Wijaya', email: 'andi@gmail.com', role: 'Developer', status: 'INACTIVE' },
  { id: 4, name: 'Rina Kartika', email: 'rina@gmail.com', role: 'HRD', status: 'ACTIVE' },
]

const EmployeeList = () => {
  return (
    <Card>
      <CardHeader 
        title="Daftar Master Karyawan" 
        action={
          <Button variant='contained' startIcon={<i className='ri-user-add-line' />}>
            Tambah Karyawan
          </Button>
        }
      />
      <TableContainer component={Paper} elevation={0}>
        <Table sx={{ minWidth: 650 }} aria-label="simple table">
          <TableHead>
            <TableRow>
              <TableCell>Nama Karyawan</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Role / Jabatan</TableCell>
              <TableCell align="center">Status</TableCell>
              <TableCell align="right">Aksi</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {mockEmployees.map((row) => (
              <TableRow key={row.id} sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                <TableCell component="th" scope="row">
                  <Typography variant='body1' fontWeight="600">{row.name}</Typography>
                </TableCell>
                <TableCell>{row.email}</TableCell>
                <TableCell>{row.role}</TableCell>
                <TableCell align="center">
                  <Chip 
                    label={row.status === 'ACTIVE' ? 'Aktif' : 'Nonaktif'} 
                    color={row.status === 'ACTIVE' ? 'success' : 'error'} 
                    size='small' 
                    variant='tonal'
                  />
                </TableCell>
                <TableCell align="right">
                  <IconButton color='primary' size='small'><i className='ri-edit-line' /></IconButton>
                  <IconButton color='error' size='small'><i className='ri-delete-bin-line' /></IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Card>
  )
}

export default EmployeeList
