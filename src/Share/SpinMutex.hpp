#pragma once
#include <atomic>
#ifdef _MSC_VER
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

#if defined(__aarch64__) || defined(__arm__) || defined(_M_ARM) || defined(_M_ARM64)
  // ARM 架构 (包括 GCC/Clang 和 MSVC)
  #ifdef _MSC_VER
    #define PAUSE() __yield()
  #else
    #define PAUSE() asm volatile("yield")
  #endif
#elif defined(_MSC_VER)
  // MSVC 在 x86/x64 架构
  #define PAUSE() _mm_pause()
#else
  // GCC/Clang 在 x86/x64 架构
  #define PAUSE() __builtin_ia32_pause()
#endif

class SpinMutex
{
private:
	std::atomic<bool> flag = { false };

public:
	void lock()
	{
		for (;;)
		{
			if (!flag.exchange(true, std::memory_order_acquire))
				break;

			while (flag.load(std::memory_order_relaxed))
			{
				PAUSE();
			}
		}
	}	

	void unlock()
	{
		flag.store(false, std::memory_order_release);
	}
};

class SpinLock
{
public:
	SpinLock(SpinMutex& mtx) :_mutex(mtx) { _mutex.lock(); }
	SpinLock(const SpinLock&) = delete;
	SpinLock& operator=(const SpinLock&) = delete;
	~SpinLock() { _mutex.unlock(); }

private:
	SpinMutex&	_mutex;
};
