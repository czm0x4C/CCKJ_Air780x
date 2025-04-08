-- 队列节点
function Node(value)
    return {value = value, next = nil}
end

-- 队列结构
function Queue()
    return {first = nil, last = nil} -- 队列的头和尾
end

-- 入队操作
function enqueue(queue, value)
    local node = Node(value)
    if queue.last then
        queue.last.next = node
    end
    queue.last = node
    if not queue.first then
        queue.first = node
    end
end

-- 出队操作
function dequeue(queue)
    if not queue.first then
        return nil
    end
    local value = queue.first.value
    queue.first = queue.first.next
    if not queue.first then
        queue.last = nil
    end
    return value
end

-- 查看队列是否为空
function isEmpty(queue)
    return not queue.first
end

-- 打印队列
function printQueue(queue)
    local current = queue.first
    while current do
        print(current.value)
        current = current.next
    end
end