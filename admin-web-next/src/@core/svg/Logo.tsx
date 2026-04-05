// React Imports
import type { SVGAttributes } from 'react'

const Logo = (props: SVGAttributes<SVGElement>) => {
  return (
    <svg width='1em' height='1em' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg' {...props}>
      <path
        d='M7 21V3H14C17.3137 3 20 5.68629 20 9C20 12.3137 17.3137 15 14 15H9V21H7ZM9 13H14C16.2091 13 18 11.2091 18 9C18 6.79086 16.2091 5 14 5H9V13Z'
        fill='currentColor'
      />
    </svg>
  )
}

export default Logo
