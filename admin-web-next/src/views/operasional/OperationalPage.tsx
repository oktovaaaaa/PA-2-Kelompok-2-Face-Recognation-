// src/views/operasional/OperationalPage.tsx
'use client'

import Grid from '@mui/material/Grid'
import Box from '@mui/material/Box'
import Typography from '@mui/material/Typography'
import AttendanceSettings from './AttendanceSettings'
import PenaltyManager from './PenaltyManager'

const OperationalPage = () => {
    return (
        <Box>
            <Box className='mbe-8'>
                <Typography variant='h4' fontWeight='800' color='primary' gutterBottom>Pengaturan Operasional</Typography>
                <Typography variant='body1' color='text.secondary'>Kelola jam kerja, kebijakan denda absensi, dan sanksi pelanggaran karyawan.</Typography>
            </Box>

            <Grid container spacing={8}>
                {/* 1. Attendance & Work Hours */}
                <Grid item xs={12}>
                    <AttendanceSettings />
                </Grid>

                {/* 2. Penalty Management */}
                <Grid item xs={12}>
                    <PenaltyManager />
                </Grid>
            </Grid>
        </Box>
    )
}

export default OperationalPage
