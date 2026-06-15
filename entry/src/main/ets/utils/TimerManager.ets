/**
 * 计时器状态
 */
class TimerStatus {
  isRunning: boolean = false;
  remaining: number = 0;
  progress: number = 0;
}

/**
 * 计时器管理器
 */
export class TimerManager {
  private static instance: TimerManager;
  private timers: Map<string, CookingTimer> = new Map();

  private constructor() {}

  static getInstance(): TimerManager {
    if (!TimerManager.instance) {
      TimerManager.instance = new TimerManager();
    }
    return TimerManager.instance;
  }

  /**
   * 创建烹饪计时器
   */
  createTimer(
    id: string,
    duration: number,
    onTick?: (remaining: number) => void,
    onComplete?: () => void
  ): CookingTimer {
    if (this.timers.has(id)) {
      this.stopTimer(id);
    }

    const timer: CookingTimer = new CookingTimer(id, duration, onTick, onComplete);
    this.timers.set(id, timer);
    return timer;
  }

  /**
   * 启动计时器
   */
  startTimer(id: string): boolean {
    const timer: CookingTimer | undefined = this.timers.get(id);
    if (timer) {
      timer.start();
      return true;
    }
    return false;
  }

  /**
   * 暂停计时器
   */
  pauseTimer(id: string): boolean {
    const timer: CookingTimer | undefined = this.timers.get(id);
    if (timer) {
      timer.pause();
      return true;
    }
    return false;
  }

  /**
   * 停止计时器
   */
  stopTimer(id: string): boolean {
    const timer: CookingTimer | undefined = this.timers.get(id);
    if (timer) {
      timer.stop();
      this.timers.delete(id);
      return true;
    }
    return false;
  }

  /**
   * 获取计时器状态
   */
  getTimerStatus(id: string): TimerStatus | null {
    const timer: CookingTimer | undefined = this.timers.get(id);
    if (timer) {
      return {
        isRunning: timer.isRunning,
        remaining: timer.remaining,
        progress: timer.progress
      };
    }
    return null;
  }

  /**
   * 停止所有计时器
   */
  stopAllTimers(): void {
    this.timers.forEach((timer: CookingTimer) => timer.stop());
    this.timers.clear();
  }

  /**
   * 格式化时间
   */
  static formatTime(seconds: number): string {
    const mins: number = Math.floor(seconds / 60);
    const secs: number = seconds % 60;
    return mins.toString().padStart(2, '0') + ':' + secs.toString().padStart(2, '0');
  }
}

/**
 * 烹饪计时器类
 */
export class CookingTimer {
  readonly id: string;
  readonly totalDuration: number;
  remaining: number;
  isRunning: boolean = false;
  private intervalId: number = -1;
  private onTick?: (remaining: number) => void;
  private onComplete?: () => void;

  constructor(
    id: string,
    duration: number,
    onTick?: (remaining: number) => void,
    onComplete?: () => void
  ) {
    this.id = id;
    this.totalDuration = duration;
    this.remaining = duration;
    this.onTick = onTick;
    this.onComplete = onComplete;
  }

  /**
   * 获取进度百分比 (0-1)
   */
  get progress(): number {
    return 1 - (this.remaining / this.totalDuration);
  }

  /**
   * 获取剩余时间格式化字符串
   */
  get formattedRemaining(): string {
    return TimerManager.formatTime(this.remaining);
  }

  /**
   * 启动计时器
   */
  start(): void {
    if (this.isRunning) return;

    this.isRunning = true;
    this.intervalId = setInterval(() => {
      this.remaining--;

      if (this.onTick) {
        this.onTick(this.remaining);
      }

      if (this.remaining <= 0) {
        this.stop();
        if (this.onComplete) {
          this.onComplete();
        }
      }
    }, 1000);
  }

  /**
   * 暂停计时器
   */
  pause(): void {
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
      this.intervalId = -1;
    }
    this.isRunning = false;
  }

  /**
   * 停止计时器
   */
  stop(): void {
    this.pause();
    this.remaining = this.totalDuration;
  }

  /**
   * 重置计时器
   */
  reset(): void {
    this.stop();
    this.remaining = this.totalDuration;
  }
}
