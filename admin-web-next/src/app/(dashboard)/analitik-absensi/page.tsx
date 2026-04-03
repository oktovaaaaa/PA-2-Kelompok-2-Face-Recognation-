// src/app/(dashboard)/analitik-absensi/page.tsx
import Grid from '@mui/material/Grid'
import AttendanceOverview from '@views/dashboard/AttendanceOverview'
import PunctualityDonut from '@views/dashboard/PunctualityDonut'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'

const AttendanceAnalyticsPage = () => {
  return (
    <Grid container spacing={6}>
      <Grid item xs={12} sm={6} md={3}>
        <Card variant='outlined' sx={{ height: '100%', borderColor: 'primary.main', borderStyle: 'dashed' }}>
          <CardContent>
            <Typography variant='body2' color='text.secondary'>Total Karyawan</Typography>
            <Typography variant='h5'>1,248</Typography>
            <Typography variant='caption' color='success.main'>+2% dari bulan lalu</Typography>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <Card variant='outlined' sx={{ height: '100%', borderColor: 'primary.main', borderStyle: 'dashed' }}>
          <CardContent>
            <Typography variant='body2' color='text.secondary'>Hadir Hari Ini</Typography>
            <Typography variant='h5'>1,152</Typography>
            <Typography variant='caption' color='primary.main'>92% Tingkat Kehadiran</Typography>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <Card variant='outlined' sx={{ height: '100%', borderColor: 'primary.main', borderStyle: 'dashed' }}>
          <CardContent>
            <Typography variant='body2' color='text.secondary'>Izin/Cuti</Typography>
            <Typography variant='h5'>34</Typography>
            <Typography variant='caption' color='warning.main'>5 Menunggu Persetujuan</Typography>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} sm={6} md={3}>
        <Card variant='outlined' sx={{ height: '100%', borderColor: 'primary.main', borderStyle: 'dashed' }}>
          <CardContent>
            <Typography variant='body2' color='text.secondary'>Terlambat</Typography>
            <Typography variant='h5'>62</Typography>
            <Typography variant='caption' color='error.main'>+12% Hari ini</Typography>
          </CardContent>
        </Card>
      </Grid>

      <Grid item xs={12} md={8}>
        <AttendanceOverview />
      </Grid>
      <Grid item xs={12} md={4}>
        <PunctualityDonut />
      </Grid>
    </Grid>
  )
}

export default AttendanceAnalyticsPage
