import type { ComponentProps } from 'react';
import { canHover } from 'src/utils/media';
import { click, hover } from 'websfx';

export type ButtonVariant = 'primary' | 'secondary' | 'mode' | 'icon';

export interface ButtonProps extends ComponentProps<'button'> {
  variant?: ButtonVariant;
}

const BASE =
  'cursor-pointer transition focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-600 active:translate-y-px';

const VARIANTS: Record<ButtonVariant, string> = {
  primary:
    'rounded-xl border-2 border-sky-700 bg-sky-700 px-6 py-3 font-semibold text-white hover:border-sky-600 hover:bg-sky-600 dark:border-sky-700 dark:bg-sky-700 dark:text-white dark:hover:border-sky-600 dark:hover:bg-sky-600',
  secondary:
    'rounded-xl border-2 border-slate-300 bg-slate-50 px-6 py-3 font-semibold text-slate-700 hover:border-sky-500 hover:shadow-md dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200 dark:hover:border-sky-400 dark:hover:shadow-md',
  mode: 'w-full rounded-xl border-2 border-slate-300 bg-slate-50 p-4 text-center hover:border-sky-500 hover:shadow-md dark:border-slate-700 dark:bg-slate-800 dark:hover:border-sky-400',
  icon: 'grid size-10 place-items-center rounded-full border-2 border-slate-300 bg-slate-50 text-slate-700 hover:border-sky-500 hover:text-sky-600 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200 dark:hover:border-sky-400',
};

/**
 * Shared button for every control in the game. Clicks always cue, hovers cue
 * only on pointer devices, and keyboard activation is cued too because Enter
 * fires the same click handler.
 *
 * @param props - Variant plus any native button props.
 * @returns The rendered button.
 */
export function Button({
  variant = 'secondary',
  className,
  onClick,
  onMouseEnter,
  type = 'button',
  ...props
}: ButtonProps) {
  return (
    <button
      {...props}
      type={type}
      className={`${BASE} ${VARIANTS[variant]}${className ? ` ${className}` : ''}`}
      onClick={(event) => {
        click();
        onClick?.(event);
      }}
      onMouseEnter={(event) => {
        if (canHover()) {
          hover();
        }
        onMouseEnter?.(event);
      }}
    />
  );
}
